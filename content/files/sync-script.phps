<?php

// this script syncs over the following things from fm_drupal to fm_drupaltest
//  - users (roles, users, users_roles);
//  - events
//  - forum topics
//  - comments
//  - stories
//  - race team stories
//  - pages

$tablestosync = array("role", "users", "users_roles", "node", "node_access", "node_comment_statistics", "node_counter", "url_alias", "comments", "quotes", "quotes_authors", "forum", "term_data", "term_hierarchy", "term_node", "history", "permission", "files", "node_revisions", "profile_fields", "profile_values", "content_type_forum", "content_type_event");

//TODO later:
// * turn lat/long stuff from users into something new

//TODO:
// * get destinations from the map and turn them into something new
// * signups?


function users_postcopy() {
	mysql_query('update users set timezone_name="America/New_York"') or die(mysql_error());
}

function comments_mapping($array) {
	unset($array{'score'});
	unset($array{'users'});
	return $array;
}

function term_node_mapping($array) {
	$array{'vid'} = $array{'nid'}; // set the revision id to the nid temporarily
	return $array;
}
function term_node_postcopy() {
	global $db1, $db2;
	$vids = mysql_query('select nid,vid from forum order by nid desc', $db2) or die(mysql_error());
	while ($row = mysql_fetch_assoc($vids)) {
		mysql_query('update term_node set vid='.$row{'vid'}.' where nid='.$row{'nid'}, $db2) or print("1");
	}
}

function node_postcopy() { 
	global $db1, $db2;
	$tnids = mysql_query('select nid,tid from term_node', $db1) or die(mysql_error());
	while ($row = mysql_fetch_assoc($tnids)) {
		mysql_query('update node set tnid='.$row{'tid'}.' where nid='.$row{'nid'}, $db2) or die(mysql_error());
	}
}

function users_mapping($array) {
	$array{'picture'} = str_replace("files/pictures/","sites/default/files/pictures/",$array{'picture'});
	return $array;
}

function content_type_event_mapping($array) {
	global $db1, $db2;
	$eventdata = mysql_query('select from_unixtime(event_start) + interval if(timezone=308, 4, 5) hour as start,from_unixtime(event_end) + interval if(timezone=308, 4, 5) hour as end from event where nid='.$array{'nid'}, $db1) or die(mysql_error());
	$row = mysql_fetch_assoc($eventdata);  //308=-4  309=-5
	$array{'field_datetime_value'} = $row{'start'};
	$array{'field_datetime_value2'} = $row{'end'};
	return $array;
}

function content_type_event_postcopy() {
	global $db1, $db2;
	$eventdata = mysql_query('select nid, from_unixtime(event_start) + interval if(timezone=308, 4, 5) hour as start,from_unixtime(event_end) + interval if(timezone=308, 4, 5) hour as end from event where nid not in (select distinct nid from content_type_event)', $db1) or die(mysql_error());
	while ($row = mysql_fetch_assoc($eventdata)) {
		$myvid = mysql_query('select vid from node where nid='.$row{'nid'}, $db1);
		$myvid = mysql_fetch_assoc($myvid);
		$row{'vid'} = $myvid{'vid'};
		mysql_query('insert into content_type_event (vid,nid,field_datetime_value,field_datetime_value2) values("'.$row{'vid'}.'","'.$row{'nid'}.'","'.$row{'start'}.'","'.$row{'end'}.'")', $db2);
	}
}

function files_mapping($array) {
	unset($array{'nid'});
	$array{'status'} = 1; 
	$array{'timestamp'} = 0;
	return $array;
}

$db1 = mysql_connect('localhost', 'live', '') or die(mysql_error());
mysql_select_db('fm_drupal', $db1) or die(mysql_error());

$db2 = mysql_connect('localhost', 'test', '') or die(mysql_error());
mysql_select_db('fm_drupaltest', $db2) or die(mysql_error());

foreach ($tablestosync as $table) {
	print("syncing $table...\n");
	mysql_query("delete from $table", $db2) or die(mysql_error());

	$result = mysql_query("select * from $table", $db1) or die(mysql_error());
	while ($row = mysql_fetch_assoc($result)) {
		$cols = '';
 		$values = '';
		if (function_exists($table.'_mapping')) {
			$row = call_user_func($table.'_mapping', $row);
		}
		foreach($row as $col => $value) {
			$cols .= $col . ',';
			if (!is_numeric($value)) {
				$values .= '"'.mysql_real_escape_string($value).'",';
			} else {
				$values .= $value.',';
			}
		}
		$cols = substr($cols, 0, -1);
		$values = substr($values, 0, -1);

		$query = "insert into $table ($cols) values($values)";
		mysql_query($query, $db2) or print(mysql_error() . " on: $query\n");
	}
	if (function_exists($table.'_postcopy')) {
		call_user_func($table.'_postcopy');
	}
}

print("clearing caches...\n");
mysql_query("delete from cache", $db2);
mysql_query("delete from cache_block", $db2);
mysql_query("delete from cache_content", $db2);
mysql_query("delete from cache_filter", $db2);
mysql_query("delete from cache_form", $db2);
mysql_query("delete from cache_menu", $db2);
mysql_query("delete from cache_page", $db2);
mysql_query("delete from cache_update", $db2);
mysql_query("delete from cache_views", $db2);
print("done!\n");

?>
