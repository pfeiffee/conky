<?php

function ctable($data) {
	
	$columns = [];
	foreach ($data as $row_key => $row) {
		foreach ($row as $cell_key => $cell) {
			$length = strlen($cell);
			if (empty($columns[$cell_key]) || $columns[$cell_key] < $length) {
				$columns[$cell_key] = $length;
			}
			if($columns[$cell_key] < strlen($cell_key)) $columns[$cell_key] = strlen($cell_key);
		}
	}

	$table = '';
	$spacer = 2;
	
	foreach ($columns as $cell_key => $cell){
		$table .= str_pad($cell_key,$cell+$spacer," ");
	}
	$table .= PHP_EOL;

	foreach ($data as $row_key => $row) {
		foreach ($row as $cell_key => $cell){
			$table .= str_pad($cell,$columns[$cell_key]+$spacer," ");
		}
		$table .= PHP_EOL;
	}
	return $table;
	
}


function join_ctable($left,$right){
	$out = "";

	$l = explode("\n",$left);
	$r = explode("\n",$right);
	
	$c = (count($l) > count($r) ? count($l) : count($r));

	$lw = strlen($l[0]);
	$lr = strlen($r[0]);
	for($i = 0; $i < $c; $i++){
		$lo = str_pad("",$lw," ");
		$ro = str_pad("",$lr," ");
		if(isset($l[$i]) && $l[$i] != "") $lo = $l[$i];
		if(isset($r[$i]) && $r[$i] != "") $ro = $r[$i];
		$out .= "$lo $ro\n";
	}

	return $out;
}

////////////////

function route(){
	$route_s = explode("\n",shell_exec("sudo route -n"));
	$route = [];

	foreach($route_s as $row){
		$rx = "/^(?P<destination>.*?)\s+(?P<gateway>.*?)\s+(?P<mask>.*?)\s+(?P<flags>.*?)\s+(?P<mss>.*?)\s+(?P<window>.*?)\s+(?P<irtt>.*?)\s+(?P<interface>.*?)\s?$/i";
		preg_match($rx,$row,$rxa);
		foreach($rxa as $k => $v) if(is_int($k)) unset($rxa[$k]);
		if(!isset($rxa['destination'])) continue;
		if($rxa['destination'] == null || $rxa['destination'] == "" || $rxa['destination'] == "Destination") continue;
		$route[] = $rxa;
	}

	return ctable($route);
}


function ports($proto = "*"){
	$ports_s = explode("\n",shell_exec("sudo netstat -tulpn"));
	$ports = [];

	foreach($ports_s as $row){
		$rx = "/^(?P<proto>.*?)\s+(?P<recv>.*?)\s+(?P<send>.*?)\s+(?P<local>.*?)\s+(?P<remote>.*?)\s+(LISTEN)?\s+(?P<pid>.*?)\s+/i";
		preg_match($rx,$row,$rxa);
		foreach($rxa as $k => $v) if(is_int($k)) unset($rxa[$k]);
		//foreach($rxa as $k => $v) $rxa[$k] = trim($rxa[$k]);
		if(!isset($rxa['proto'])) continue;
		if($rxa['proto'] == null || $rxa['proto'] == "" || $rxa['proto'] == " " || $rxa['proto'] == "Proto") continue;
		$ports[] = $rxa;
	}


	foreach($ports as $k => $p){
		unset($ports[$k]['recv']);
		unset($ports[$k]['send']);
		unset($ports[$k]['remote']);
		
		if($proto != "*"){
			if($ports[$k]['proto'] != $proto) unset($ports[$k]);		
		}
	}


	return ctable($ports);
}

function connections($blockpid = ""){
	$ports_s = explode("\n",shell_exec("sudo netstat -tupn"));
	$ports = [];

	foreach($ports_s as $row){
		$rx = "/^(?P<proto>.*?)\s+(?P<recv>.*?)\s+(?P<send>.*?)\s+(?P<local>.*?)\s+(?P<remote>.*?)\s+(?P<state>.*?)\s+(?P<pid>.*?)\s+/i";
		preg_match($rx,$row,$rxa);
		foreach($rxa as $k => $v) if(is_int($k)) unset($rxa[$k]);
		if(!isset($rxa['proto'])) continue;
		if($rxa['proto'] == null || $rxa['proto'] == "" || $rxa['proto'] == "Proto") continue;
		$ports[] = $rxa;
	}


	foreach($ports as $k => $p){
		unset($ports[$k]['recv']);
		unset($ports[$k]['send']);
		if($blockpid != "" && preg_match("/$blockpid/i",$ports[$k]['pid']) === 1) unset($ports[$k]);
	}

	return ctable($ports);
}

function page_ports4(){
	return join_ctable(ports("tcp"),ports("udp"));
}

function page_ports6(){
	return join_ctable(ports("tcp6"),ports("udp6"));
}

function connections_filter(){
	return connections("chrome");
}

echo $argv[1]();






?>
