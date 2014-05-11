<?php
/**
   ::::::::::::::: www.blogging-it.com :::::::::::::::
   
Version 1.0
   
Copyright (C) 2014 Markus Eschenbach. All rights reserved.


This software is provided on an "as-is" basis, without any express or implied warranty.
In no event shall the author be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter and redistribute it,
provided that the following conditions are met:

1. All redistributions of source code files must retain all copyright
   notices that are currently in place, and this list of conditions without
   modification.

2. All redistributions in binary form must retain all occurrences of the
   above copyright notice and web site addresses that are currently in
   place (for example, in the About boxes).

3. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software to
   distribute a product, an acknowledgment in the product documentation
   would be appreciated but is not required.

4. Modified versions in source or binary form must be plainly marked as
   such, and must not be misrepresented as being the original software.
   
   ::::::::::::::: www.blogging-it.com :::::::::::::::
*/

 

// ************* CONFIGURATION ************* 

$websites = array(
        array('url' => 'www.blogging-it.com', 'name' => 'Blogging-IT', 'search' => 'head'),
        array('url' => 'www.google.de', 'name' => 'Google')
);

$VERSION = '1.0';
$COL_RED = "31"; 	//bash color escape code
$COL_GREEN = "32";  //bash color escape code

$NEWLINE = "\n";	//new line character
$spacer = -1;		//default value for space size

$default_exec_time = 100; //Default time (in seconds) to limit the maximum execution time
$socket_timeout = 10; //default timeout (in seconds) for socket based streams 
$maxResponseTime=5; //warning if the response time is bigger

$user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-GB; rv:1.9.0.3) Gecko/2008092417 Firefox/3.0.3'; //default user agent


// ************* INIT ************* 

foreach ($websites as $j => $svr)$spacer = (strlen($svr['name']) > $spacer-10) ? (strlen($svr['name'])+10) : $spacer;
ini_set('display_errors','Off');
ini_set("default_socket_timeout",$socket_timeout);
ini_set('user_agent',$user_agent);
set_time_limit($default_exec_time);

// ************* METHODS ************* 

function colorize($text,$col){return "\033[".$col."m". $text. "\033[0m";}
function showHeader(){return "\033[1m" . 'Website UP Checker ' . "\033[0m" . $VERSION . '  (last check: ' . date('d.m.Y H:i:s') . ')';}

function spacer($txt,$no){return str_pad($txt, $no, " ", STR_PAD_RIGHT);}
function formatPing($ping){return " (" . spacer($ping,(strlen($ping)+(6-strlen($ping)))) . "ms) ";}
function diffTime($start,$end){return round((array_sum(explode(' ', $end)) - array_sum(explode(' ', $start)))*1000);};

function searchString($fp,$searchKey){
  if(empty($searchKey))return true;
  stream_set_blocking($fp, 0);$data = '';$found = false;
  while (!feof($fp) && !$found){$data .= stream_get_line($fp, 1024);$found = (strpos($data, $searchKey, 0) != 0) ? true : false;}
  return $found;
}


// ************* MAIN ************* 

echo showHeader();
echo $NEWLINE . $NEWLINE;

foreach ($websites as $i => $serverInfos) {
	$statusMSG = "";
	$statusType = 'OFFLINE';

	$curURL = $serverInfos['url'];
	$curName = $serverInfos['name'];

	if(strpos($curURL, '://') === false){
		$curURL = "http://" . $curURL;
	}
	
	$timestart = microtime(true);
	$http_response_header = null;
  	$fp=fopen($curURL,"r");


	$responseCodeOK = strpos($http_response_header[0], '200');

	if($fp){

		if($responseCodeOK != 0){
			if(!searchString($fp,$serverInfos['search'])){
				$statusMSG = 'Search-text not found';
				$statusType = 'ERROR';
			}else{
				$statusType = 'ONLINE';
			}
			
		}		
	}



	$timeend = microtime(true);	
	$ping = diffTime($timestart,$timeend);
	
	$toSlow = false;

	if(!$fp){
		if($http_response_header[0] == false && ($socket_timeout*1000) < $ping){
				$statusMSG = 'Timeout';
		}else if($http_response_header[0]){
			$statusMSG = $http_response_header[0];
		}else{
			$statusMSG = 'Unknown Error';
		}
		$statusType = 'ERROR';
	}else{
		if(($maxResponseTime*1000) < $ping){
			$statusMSG = ' - to slow - ' . $statusMSG;
			$toSlow = true;
		}
	}

	fclose($fp);
	$ping = formatPing($ping);
	$pingSpacer = strlen($socket_timeout*1000)+ 8;
	if($toSlow){
		$ping = colorize($ping,$COL_RED);
	}
	
	$statusType = colorize($statusType . " ",($statusType == 'ONLINE') ? $COL_GREEN : $COL_RED);

	echo spacer($curName,$spacer) . spacer($statusType,18) .  spacer($ping,$pingSpacer) . $statusMSG .  $NEWLINE;

}

?>