<?php
#
# Plugin: check_centricstor
# Author: Rene Koch <r.koch@ovido.at>
# Date: 2012/12/06
#

$opt[1] = "--vertical-label \"Caches free\" -l 0 --title \"Caches free on $hostname\" --slope-mode -N";
$opt[2] = "--vertical-label \"Caches dirty\" -l 0 --title \"Caches dirty on $hostname\" --slope-mode -N";
$def[1] = "";
$def[2] = "";

# process cache usage statistics
foreach ($this->DS as $key=>$val){
  $ds = $val['DS'];
  if (preg_match("/_free/", $val['NAME']) ){
    $def[1] .= "DEF:var$key=$RRDFILE[$ds]:$ds:AVERAGE ";
    $label = preg_split("/_/", $LABEL[$ds]);
    $def[1] .= "LINE1:var$key#" . color() . ":\"" . $label[0] ."      \" ";
    $def[1] .= "GPRINT:var$key:LAST:\"last\: %3.4lg%% \" ";
    $def[1] .= "GPRINT:var$key:MAX:\"max\: %3.4lg%% \" ";
    $def[1] .= "GPRINT:var$key:AVERAGE:\"average\: %3.4lg%% \"\\n ";
  }else{
    $def[2] .= "DEF:var$key=$RRDFILE[$ds]:$ds:AVERAGE ";
    $label = preg_split("/_/", $LABEL[$ds]);
    $def[2] .= "LINE1:var$key#" . color() . ":\"" . $label[0] ."      \" ";
    $def[2] .= "GPRINT:var$key:LAST:\"last\: %3.4lg%% \" ";
    $def[2] .= "GPRINT:var$key:MAX:\"max\: %3.4lg%% \" ";
    $def[2] .= "GPRINT:var$key:AVERAGE:\"average\: %3.4lg%% \"\\n ";
  }
}

# generate html color code
function color(){
  $color = dechex(rand(0,10000000));
  while (strlen($color) < 6){
    $color = dechex(rand(0,10000000));
  }
  return $color;
}

?>

