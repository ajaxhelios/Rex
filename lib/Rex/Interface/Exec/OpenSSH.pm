#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Interface::Exec::OpenSSH;
   
use strict;
use warnings;

use Rex::Helper::SSH2;
require Rex::Commands;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub exec {
   my ($self, $cmd, $path, $option) = @_;

   if(exists $option->{cwd}) {
      $cmd = "cd " . $option->{cwd} . " && $cmd";
   }

   Rex::Logger::debug("Executing: $cmd");

   if($path) { $path = "PATH=$path" }
   $path ||= "";

   Rex::Commands::profiler()->start("exec: $cmd");

   my $ssh = Rex::is_ssh();

   my ($shell) = $ssh->capture("echo \$SHELL");
   $shell ||= "bash";

   my ($out, $err);
   if($shell !~ m/\/bash/ && $shell !~ m/\/sh/) {
      ($out, $err) = $ssh->capture2($cmd);
   }
   else {

      my $new_cmd = "LC_ALL=C $path ; export PATH LC_ALL ; $cmd";

      if(Rex::Config->get_source_global_profile) {
         $new_cmd = ". /etc/profile; $new_cmd";
      }

      ($out, $err) = $ssh->capture2($new_cmd);
   }

   Rex::Commands::profiler()->end("exec: $cmd");

   Rex::Logger::debug($out) if ($out);
   if($err) {
      Rex::Logger::debug("========= ERR ============");
      Rex::Logger::debug($err);
      Rex::Logger::debug("========= ERR ============");
   }

   if(wantarray) { return ($out, $err); }

   return $out;
}

1;
