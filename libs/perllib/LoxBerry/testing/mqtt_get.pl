#!/usr/bin/perl

use warnings;
use strict;
use LoxBerry::IO;

$LoxBerry::IO::DEBUG = 1;

mqtt_publish( "hallo/du", "Wie gehts dir Sabine" );
mqtt_retain( "hallo/ich", "Schöner Tag heute" );
 
print mqtt_get( "hallo/du" ) . "\n";
print mqtt_get( "hallo/ich" ) . "\n";
