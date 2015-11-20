#!/usr/bin/perl -w
#
# create_menu.pl - v3.7
#
# This script creates the user desktop menu
#
# Created by Nimesh Jethwa <njethwa@cirruscomputing.com>
#
# Copyright (c) 1996-2015 Free Open Source Solutions Inc.
# All Rights Reserved 
#
# Free Open Source Solutions Inc. owns and reserves all rights, title,
# and interest in and to this software in both machine and human
# readable forms.
#

#Imports and declarations
use Getopt::Long;
use Sys::Syslog;

my @capabilities_enabled;

GetOptions('capabilities_enabled=s@' => \@capabilities_enabled, 'applications_menu_filename=s' => \$applications_menu_filename, 'settings_menu_filename=s' => \$settings_menu_filename) or die ("Options set incorrectly");

@capabilities_enabled = map {glob ($_)} @capabilities_enabled;

sub has_enabled_capability{
    my $target = shift;
    #Determine if capability is enabled
    foreach my $cap_e (@capabilities_enabled){
	if ($target eq $cap_e){
	    return 1;
	}
    }
    return 0;
}

my $applications_menu = <<EOF;
<!DOCTYPE Menu
  PUBLIC '-//freedesktop//DTD Menu 1.0//EN'
  'http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd'>
<Menu>
	<Name>Applications</Name>
	<Directory>X-GNOME-Menu-Applications.directory</Directory>
	<!-- Scan legacy dirs first, as later items take priority -->
	<LegacyDir>/etc/X11/applnk</LegacyDir>
	<LegacyDir>/usr/share/gnome/apps</LegacyDir>
	<!-- Read standard .directory and .desktop file locations -->
	<DefaultAppDirs/>
	<DefaultDirectoryDirs/>
	<!-- Read in overrides and child menus from applications-merged/ -->
	<DefaultMergeDirs/>
EOF
	if (has_enabled_capability("Email") || has_enabled_capability("Internet") || has_enabled_capability("InstantMessaging") || has_enabled_capability("Syncthing") || has_enabled_capability("SOGo")){
		$applications_menu .= <<EOF;
	<!-- Internet -->
	<Menu>
		<Name>Internet</Name>
		<Directory>internet.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("Email")){
			$applications_menu .= <<EOF;
			<Filename>evolution.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Internet")){
			$applications_menu .= <<EOF;
			<Filename>firefox.desktop</Filename>
EOF
		}
		if (has_enabled_capability("InstantMessaging")){
			$applications_menu .= <<EOF;
			<Filename>pidgin.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Syncthing")){
			$applications_menu .= <<EOF;
			<Filename>syncthing.desktop</Filename>
EOF
		}
		if (has_enabled_capability("SOGo")){
			$applications_menu .= <<EOF;
			<Filename>sogo.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("Email")){
			$applications_menu .= <<EOF;
			<Filename>evolution.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Internet")){
			$applications_menu .= <<EOF;
			<Filename>firefox.desktop</Filename>
EOF
		}
		if (has_enabled_capability("InstantMessaging")){
			$applications_menu .= <<EOF;
			<Filename>pidgin.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Syncthing")){
			$applications_menu .= <<EOF;
			<Filename>syncthing.desktop</Filename>
EOF
		}
		if (has_enabled_capability("SOGo")){
			$applications_menu .= <<EOF;
			<Filename>sogo.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Internet -->
EOF
        }
	if (has_enabled_capability("LibreOffice")){
		$applications_menu .= <<EOF;
	<!-- Office -->
	<Menu>
		<Name>Office</Name>
		<Directory>office.directory</Directory>
		<Include>
			<Filename>openoffice.org-writer.desktop</Filename>
			<Filename>openoffice.org-calc.desktop</Filename>
			<Filename>openoffice.org-impress.desktop</Filename>
			<Filename>openoffice.org-draw.desktop</Filename>
			<Filename>openoffice.org-base.desktop</Filename>
			<Filename>openoffice.org-math.desktop</Filename>
		</Include>
		<Layout>
			<Merge type="menus"/>
			<Filename>openoffice.org-writer.desktop</Filename>
			<Filename>openoffice.org-calc.desktop</Filename>
			<Filename>openoffice.org-impress.desktop</Filename>
			<Filename>openoffice.org-draw.desktop</Filename>
			<Filename>openoffice.org-base.desktop</Filename>
			<Filename>openoffice.org-math.desktop</Filename>
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Office -->
EOF
	}
	if (has_enabled_capability("Gimp") || has_enabled_capability("Scribus") || has_enabled_capability("Inkscape") || has_enabled_capability("Lector")){
		$applications_menu .= <<EOF;
	<!-- Graphics -->
	<Menu>
		<Name>Graphics</Name>
		<Directory>graphics.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("Gimp")){
			$applications_menu .= <<EOF;
			<Filename>gimp.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Scribus")){
			$applications_menu .= <<EOF;
			<Filename>scribus.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Inkscape")){
			$applications_menu .= <<EOF;
			<Filename>inkscape.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Lector")){
			$applications_menu .= <<EOF;
			<Filename>lector.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("Gimp")){
			$applications_menu .= <<EOF;
			<Filename>gimp.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Scribus")){
			$applications_menu .= <<EOF;
			<Filename>scribus.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Inkscape")){
			$applications_menu .= <<EOF;
			<Filename>inkscape.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Lector")){
			$applications_menu .= <<EOF;
			<Filename>lector.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Graphics -->
EOF
	}
	if (has_enabled_capability("Vtiger") || has_enabled_capability("Nuxeo") || has_enabled_capability("Trac") || has_enabled_capability("MailingLists") || has_enabled_capability("Wiki")){
		$applications_menu .= <<EOF;
	<!-- Collaboration -->
	<Menu>
		<Name>Collaboration</Name>
		<Directory>collaboration.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("Vtiger")){
		$applications_menu .= <<EOF;
			<Filename>vtiger.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Nuxeo")){
			$applications_menu .= <<EOF;
			<Filename>nuxeo.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Trac")){
			$applications_menu .= <<EOF;
			<Filename>trac.desktop</Filename>
EOF
		}
		if (has_enabled_capability("MailingLists")){
			$applications_menu .= <<EOF;
			<Filename>mailinglists.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Wiki")){
			$applications_menu .= <<EOF;
			<Filename>wiki.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("Vtiger")){
		$applications_menu .= <<EOF;
			<Filename>vtiger.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Nuxeo")){
			$applications_menu .= <<EOF;
			<Filename>nuxeo.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Trac")){
			$applications_menu .= <<EOF;
			<Filename>trac.desktop</Filename>
EOF
		}
		if (has_enabled_capability("MailingLists")){
			$applications_menu .= <<EOF;
			<Filename>mailinglists.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Wiki")){
			$applications_menu .= <<EOF;
			<Filename>wiki.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Collaboration -->
EOF
	}
	if (has_enabled_capability("ProjectLibre") || has_enabled_capability("Redmine")){
		$applications_menu .= <<EOF;
	<!-- Projects -->
	<Menu>
		<Name>Projects</Name>
		<Directory>projects.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("ProjectLibre")){
			$applications_menu .= <<EOF;
			<Filename>projectlibre.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Redmine")){
			$applications_menu .= <<EOF;
			<Filename>redmine.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("ProjectLibre")){
			$applications_menu .= <<EOF;
			<Filename>projectlibre.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Redmine")){
			$applications_menu .= <<EOF;
			<Filename>redmine.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Projects -->
EOF
	}
	if (has_enabled_capability("FreeMind") || has_enabled_capability("VUE")){
		$applications_menu .= <<EOF;
	<!-- Visualization -->
	<Menu>
		<Name>Visualization</Name>
		<Directory>visualization.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("FreeMind")){
			$applications_menu .= <<EOF;
			<Filename>freemind.desktop</Filename>
EOF
		}
		if (has_enabled_capability("VUE")){
			$applications_menu .= <<EOF;
			<Filename>vue.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("FreeMind")){
			$applications_menu .= <<EOF;
			<Filename>freemind.desktop</Filename>
EOF
		}
		if (has_enabled_capability("VUE")){
			$applications_menu .= <<EOF;
			<Filename>vue.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Visualization -->
EOF
	}
	if (has_enabled_capability("SQLLedger") || has_enabled_capability("Timesheet")){
		$applications_menu .= <<EOF;
	<!-- Financial -->
	<Menu>
		<Name>Financial</Name>
		<Directory>financial.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("SQLLedger")){
			$applications_menu .= <<EOF;
			<Filename>sqlledger.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Timesheet")){
			$applications_menu .= <<EOF;
			<Filename>timesheet.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("SQLLedger")){
			$applications_menu .= <<EOF;
			<Filename>sqlledger.desktop</Filename>
EOF
		}
		if (has_enabled_capability("Timesheet")){
			$applications_menu .= <<EOF;
			<Filename>timesheet.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Financial -->
EOF
	}
	if (has_enabled_capability("OrangeHRM") || has_enabled_capability("PHPScheduleIt")){
		$applications_menu .= <<EOF;
	<!-- Enterprise -->
	<Menu>
		<Name>Enterprise</Name>
		<Directory>enterprise.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("OrangeHRM")){
			$applications_menu .= <<EOF;
			<Filename>orangehrm.desktop</Filename>
EOF
		}
		if (has_enabled_capability("PHPScheduleIt")){
			$applications_menu .= <<EOF;
			<Filename>phpscheduleit.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("OrangeHRM")){
			$applications_menu .= <<EOF;
			<Filename>orangehrm.desktop</Filename>
EOF
		}
		if (has_enabled_capability("PHPScheduleIt")){
			$applications_menu .= <<EOF;
			<Filename>phpscheduleit.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Enterprise -->
EOF
	}
	if (has_enabled_capability("Moodle")){
		$applications_menu .= <<EOF;
	<!-- Education -->
	<Menu>
		<Name>Education</Name>
		<Directory>education.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("Moodle")){
			$applications_menu .= <<EOF;
			<Filename>moodle.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("Moodle")){
			$applications_menu .= <<EOF;
			<Filename>moodle.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Education -->
EOF
	}
	if (has_enabled_capability("OpenERP")){
		$applications_menu .= <<EOF;
	<!-- Manufacturing -->
	<Menu>
		<Name>Manufacturing</Name>
		<Directory>manufacturing.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("OpenERP")){
			$applications_menu .= <<EOF;
			<Filename>openerp.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("OpenERP")){
			$applications_menu .= <<EOF;
			<Filename>openerp.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Manufacturing -->
EOF
	}
	if (has_enabled_capability("Oscar")){
		$applications_menu .= <<EOF;
	<!-- Medical -->
	<Menu>
		<Name>Medical</Name>
		<Directory>medical.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("Oscar")){
			$applications_menu .= <<EOF;
			<Filename>oscar.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF
		if (has_enabled_capability("Oscar")){
			$applications_menu .= <<EOF;
			<Filename>oscar.desktop</Filename>
EOF
		}
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Medical -->
EOF
	}
	if (has_enabled_capability("CiviCRM") || has_enabled_capability("ChurchInfo")){
		$applications_menu .= <<EOF;
	<!-- Non-Profit -->
	<Menu>
		<Name>Non-Profit</Name>
		<Directory>non-profit.directory</Directory>
		<Include>
EOF
		if (has_enabled_capability("CiviCRM")){
			$applications_menu .= <<EOF;
			<Filename>civicrm.desktop</Filename>
EOF
		}
		if (has_enabled_capability("ChurchInfo")){
                        $applications_menu .= <<EOF;
                        <Filename>churchinfo.desktop</Filename>
EOF
                }
		$applications_menu .= <<EOF;
		</Include>
		<Layout>
			<Merge type="menus"/>
EOF

		if (has_enabled_capability("CiviCRM")){
                        $applications_menu .= <<EOF;
                        <Filename>civicrm.desktop</Filename>
EOF
                }
		if (has_enabled_capability("ChurchInfo")){
                        $applications_menu .= <<EOF;
                        <Filename>churchinfo.desktop</Filename>
EOF
                }
		$applications_menu .= <<EOF;
			<Merge type="files"/>
		</Layout>
	</Menu>
	<!-- End Non-Profit -->
EOF
	}
	$applications_menu .= <<EOF;
	<!-- Accessories submenu -->
	<Menu>
		<Name>Accessories</Name>
		<Directory>accessories.directory</Directory>
		<Include>
			<Filename>gnome-terminal.desktop</Filename>
			<Filename>gcalctool.desktop</Filename>
			<Filename>gucharmap.desktop</Filename>
			<Filename>gnome-dictionary.desktop</Filename>
			<Filename>redhat-manage-print-jobs.desktop</Filename>
			<Filename>seahorse.desktop</Filename>
			<Filename>gnome-screenshot.desktop</Filename>
			<Filename>gedit.desktop</Filename>
			<Filename>tomboy.desktop</Filename>
			<Filename>tracker-search-tool.desktop</Filename>
		</Include>
	</Menu>
	<!-- End Accessories -->
	<!-- Games -->
	<Menu>
		<Name>Games</Name>
		<Directory>games.directory</Directory>
		<Include>
			<And>
				<Category>Game</Category>
				<Not>
					<Category>ActionGame</Category>
				</Not>
				<Not>
					<Category>AdventureGame</Category>
				</Not>
				<Not>
					<Category>ArcadeGame</Category>
				</Not>
				<Not>
					<Category>BoardGame</Category>
				</Not>
				<Not>
					<Category>BlocksGame</Category>
				</Not>
				<Not>
					<Category>CardGame</Category>
				</Not>
				<Not>
					<Category>KidsGame</Category>
				</Not>
				<Not>
					<Category>LogicGame</Category>
				</Not>
				<Not>
					<Category>RolePlaying</Category>
				</Not>
				<Not>
					<Category>Simulation</Category>
				</Not>
				<Not>
					<Category>SportsGame</Category>
				</Not>
				<Not>
					<Category>StrategyGame</Category>
				</Not>
			</And>
		</Include>
		<DefaultLayout inline="true" inline_header="false" inline_limit="6">
			<Merge type="menus"/>
			<Merge type="files"/>
		</DefaultLayout>
		<Menu>
			<Name>Action</Name>
			<Directory>ActionGames.directory</Directory>
			<Include>
				<Category>ActionGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Adventure</Name>
			<Directory>AdventureGames.directory</Directory>
			<Include>
				<Category>AdventureGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Arcade</Name>
			<Directory>ArcadeGames.directory</Directory>
			<Include>
				<Category>ArcadeGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Board</Name>
			<Directory>BoardGames.directory</Directory>
			<Include>
				<Category>BoardGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Blocks</Name>
			<Directory>BlocksGames.directory</Directory>
			<Include>
				<Category>BlocksGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Cards</Name>
			<Directory>CardGames.directory</Directory>
			<Include>
				<Category>CardGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Kids</Name>
			<Directory>KidsGames.directory</Directory>
			<Include>
				<Category>KidsGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Logic</Name>
			<Directory>LogicGames.directory</Directory>
			<Include>
				<Category>LogicGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Role Playing</Name>
			<Directory>RolePlayingGames.directory</Directory>
			<Include>
				<Category>RolePlaying</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Simulation</Name>
			<Directory>SimulationGames.directory</Directory>
			<Include>
				<Category>Simulation</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Sports</Name>
			<Directory>SportsGames.directory</Directory>
			<Include>
				<Category>SportsGame</Category>
			</Include>
		</Menu>
		<Menu>
			<Name>Strategy</Name>
			<Directory>StrategyGames.directory</Directory>
			<Include>
				<Category>StrategyGame</Category>
			</Include>
		</Menu>
	</Menu>
	<!-- End Games -->
	<!-- Main application menu -->
	<Include>
EOF
	$applications_menu .= <<EOF;
		<Filename>cirrusopen-cloudmanager.desktop</Filename>
		<Filename>gnomecc.desktop</Filename>
	</Include>
	<Layout>
		<Merge type="menus"/>
EOF
	if (has_enabled_capability("Email")){
		$applications_menu .= <<EOF;
		<Filename>evolution.desktop</Filename>
EOF
	}
	if (has_enabled_capability("Internet")){
		$applications_menu .= <<EOF;
		<Filename>firefox.desktop</Filename>
EOF
	}
	if (has_enabled_capability("Email") || has_enabled_capability("Internet") || has_enabled_capability("InstantMessaging") || has_enabled_capability("Syncthing") || has_enabled_capability("SOGo")){
		$applications_menu .= <<EOF;
		<Menuname>Internet</Menuname>
EOF
	}
	if (has_enabled_capability("LibreOffice")){
		$applications_menu .= <<EOF;
		<Menuname>Office</Menuname>
EOF
	}
	if (has_enabled_capability("Vtiger") || has_enabled_capability("Nuxeo") || has_enabled_capability("Trac") || has_enabled_capability("MailingLists") || has_enabled_capability("Wiki")){
		$applications_menu .= <<EOF;
		<Menuname>Collaboration</Menuname>
EOF
	}
	if (has_enabled_capability("OrangeHRM") || has_enabled_capability("PHPScheduleIt")){
		$applications_menu .= <<EOF;
		<Menuname>Enterprise</Menuname>
EOF
	}
	if (has_enabled_capability("SQLLedger") || has_enabled_capability("Timesheet")){
		$applications_menu .= <<EOF;
		<Menuname>Financial</Menuname>
EOF
	}
	if (has_enabled_capability("Gimp") || has_enabled_capability("Scribus") || has_enabled_capability("Inkscape") || has_enabled_capability("Lector")){
		$applications_menu .= <<EOF;
		<Menuname>Graphics</Menuname>
EOF
	}
	if (has_enabled_capability("ProjectLibre") || has_enabled_capability("Redmine")){
		$applications_menu .= <<EOF;
		<Menuname>Projects</Menuname>
EOF
	}
	if (has_enabled_capability("FreeMind") || has_enabled_capability("VUE")){
		$applications_menu .= <<EOF;
		<Menuname>Visualization</Menuname>
EOF
	}
	if (has_enabled_capability("SOGo")){
		$applications_menu .= <<EOF;
		<Filename>sogo.desktop</Filename>
EOF
	}
	if (has_enabled_capability("Moodle")){
		$applications_menu .= <<EOF;
		<Menuname>Education</Menuname>
EOF
	}
	if (has_enabled_capability("OpenERP")){
		$applications_menu .= <<EOF;
		<Menuname>Manufacturing</Menuname>
EOF
	}
	if (has_enabled_capability("Oscar")){
		$applications_menu .= <<EOF;
		<Menuname>Medical</Menuname>
EOF
	}
	if (has_enabled_capability("CiviCRM") || has_enabled_capability("ChurchInfo")){
		$applications_menu .= <<EOF;
		<Menuname>Non-Profit</Menuname>
EOF
	}
	$applications_menu .= <<EOF;
		<Filename>cirrusopen-cloudmanager.desktop</Filename>
		<Menuname>Accessories</Menuname>
		<Menuname>Games</Menuname>
		<Filename>gnomecc.desktop</Filename>
		<Merge type="files"/>
	</Layout>
</Menu>
<!-- End Applications -->
EOF

open (MYFILE1, ">$applications_menu_filename");
print MYFILE1 "$applications_menu";
close (MYFILE1);


my $settings_menu = <<EOF;
<!DOCTYPE Menu
  PUBLIC '-//freedesktop//DTD Menu 1.0//EN'
  'http://standards.freedesktop.org/menu-spec/menu-1.0.dtd'>
<Menu>
        <Name>Desktop</Name>
        <MergeFile type="parent">/etc/xdg/menus/settings.menu</MergeFile>
</Menu>
EOF

open (MYFILE2, ">$settings_menu_filename");
print MYFILE2 "$settings_menu";
close (MYFILE2);
