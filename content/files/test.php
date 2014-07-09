<?php 
header("Content-type: text/plain");
require("XML/RPC.php");

$client = new XML_RPC_Client('/gdev/gallery2/main.php?g2_view=xmlrpc:XmlRpc','ckdake.com');
$client->setDebug(0);

print("
PEAR::XML_RPC Demo for Gallery 2 XML RPC Module
see http://ckdake.com/files/test.phps for the source code
left to implement and demo:
-move item
left to demo:
-create link
-set item order weight
");

print("\n\n::Logging in to the system::\n\n");
$msg = new XML_RPC_Message('login',array(new XML_RPC_Value('test'),new XML_RPC_Value('test')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");
$response = $res->value();
$authval = $response->structmem('authToken');
$authtoken = $authval->scalarval();


print("\n\n::Getting information about the server::\n\n");
$msg = new XML_RPC_Message('getServerInfo');
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");

$array = $res->value(); 
$val = $array->structmem('rootId');
$rootid = $val->scalarval();


print("\n\n::Checking to see if we are logged in::\n\n");
$msg = new XML_RPC_Message('checkLoggedIn',array(new XML_RPC_Value($authtoken)));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");


print("\n\n::getting item property keys of the root node::\n\n");
$msg = new XML_RPC_Message('fetchItemPropertyKeys',array(new XML_RPC_Value($authtoken,'string'), new XML_RPC_Value($rootid,'int')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");


$keyarray = array();
$array = $res->value();
for ($i = 0; $i < $array->arraysize(); $i++) {
        $item = $array->arraymem($i);
	$mykey = $item->scalarval();
	$keyarray[] = new XML_RPC_Value($mykey);
}

print("\n\n::getting the property values of the root node with the keys from above::\n\n");
$msg = new XML_RPC_Message('fetchItemProperties',array(new XML_RPC_Value($authtoken, 'string'), 
							new XML_RPC_Value($rootid, 'int'), 
							new XML_RPC_Value($keyarray, 'array')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");
			

print("\n\n::fetching the children of the root node::\n\n");
$msg = new XML_RPC_Message('fetchChildItems',array(new XML_RPC_Value($authtoken, 'string'), new XML_RPC_Value($rootid, 'int')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");

$idarray = array();
$array = $res->value();
for ($i = 0; $i < $array->arraysize(); $i++) {
	$item = $array->arraymem($i);
	$idobject = $item->structmem('thumbId');
	$myid = $idobject->scalarval();
	$idarray[] = new XML_RPC_Value($myid);
}


print("\n\n::fetching the URLs for the root nodes' childrens' thumbnails ::\n\n");
$msg = new XML_RPC_Message('getItemUrls',array(new XML_RPC_Value($authtoken),
					new XML_RPC_Value($idarray,'array')));
print($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");

print("\n\n::makeing a test album::\n\n");
$msg = new XML_RPC_Message('createAlbum',array(new XML_RPC_Value($authtoken, 'string'), 
						new XML_RPC_Value($rootid, 'int'),
						new XML_RPC_Value('testAlbumName', 'string'),
						new XML_RPC_Value('testAlbumTitle', 'string'),
						new XML_RPC_Value('testAlbumSummary', 'string'),
						new XML_RPC_Value('testAlbumDescription', 'string'),
						new XML_RPC_Value('testAlbumKeyword', 'string')));
print_r($msg->serialize(). "\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");

$val = $res->value();
$newAlbumId = $val->scalarval();


print("\n\n::getting item property keys of the test album::\n\n");
$msg = new XML_RPC_Message('fetchItemPropertyKeys',array(new XML_RPC_Value($authtoken,'string'), new XML_RPC_Value($newAlbumId,'int')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");


$keyarray = array();
$array = $res->value();
for ($i = 0; $i < $array->arraysize(); $i++) {
        $item = $array->arraymem($i);
        $mykey = $item->scalarval();
        $keyarray[] = new XML_RPC_Value($mykey);
}

print("\n\n::getting the property values of the test album with the keys from above::\n\n");
$msg = new XML_RPC_Message('fetchItemProperties',array(new XML_RPC_Value($authtoken, 'string'),
                                                        new XML_RPC_Value($newAlbumId, 'int'),
                                                        new XML_RPC_Value($keyarray, 'array')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");

print("\n\n::setting the title of the test album::\n\n");
$msg = new XML_RPC_Message('setItemProperties',array(new XML_RPC_Value($authtoken, 'string'),
							new XML_RPC_Value($newAlbumId, 'int'),
							new XML_RPC_Value(array(new XML_RPC_Value('title', 'string')), 'array'),
							new XML_RPC_Value(array(new XML_RPC_Value('my awesome new album title', 'string')), 'array')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");


print("\n\n::getting the new title of the test album::\n\n");
$msg = new XML_RPC_Message('fetchItemProperties', array(new XML_RPC_Value($authtoken, 'string'),
							new XML_RPC_Value($newAlbumId, 'int'),
							new XML_RPC_Value(array(new XML_RPC_Value('title', 'string')), 'array')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");


print("\n\n::adding an image to the album::\n\n");

$fd = fopen("/home/ckdake/public_html/files/ck.png",'rb');
$size = filesize("/home/ckdake/public_html/files/ck.png");
$cont = fread($fd, $size);
fclose($fd);
$imagedata = base64_encode($cont);

$msg = new XML_RPC_Message('addItemToAlbum', array(new XML_RPC_Value($authtoken, 'string'), 
							new XML_RPC_Value('myItemName', 'string'),
							new XML_RPC_Value('myTitle', 'string'),
							new XML_RPC_Value('mySummary', 'string'),
							new XML_RPC_Value('myDescription', 'string'),
							new XML_RPC_Value('image/png', 'string'),
							new XML_RPC_Value($newAlbumId, 'int'),
							new XML_RPC_Value($imagedata, 'base64')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");
$val = $res->value();
$newItemId = $val->scalarval();

print("\n\n::fetching the full sized copy of the  item::\n\n");
$msg = new XML_RPC_Message('getItems',array(new XML_RPC_Value($authtoken, 'string'),
                                                new XML_RPC_Value(0, 'int'),
						new XML_RPC_Value(array(new XML_RPC_Value($newItemId, 'int')), 'array')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");
												

print("\n\n::fetching a resized version of the item::\n\n");
$msg = new XML_RPC_Message('getItems',array(new XML_RPC_Value($authtoken, 'string'),
						new XML_RPC_Value(150, 'int'),
						new XML_RPC_Value(array(new XML_RPC_Value($newItemId, 'int')), 'array')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");

$res = $client->send($msg);
print_r($res->serialize() . "\n");						

print("\n\n::fetching the children of the parent album::\n\n");
$msg = new XML_RPC_Message('fetchChildItems',array(new XML_RPC_Value($authtoken, 'string'), new XML_RPC_Value($newAlbumId, 'int')));
print_r($msg->serialize()."\n");
$res = $client->send($msg);
print_r($res->serialize()."\n");

$idarray = array();
$array = $res->value();
for ($i = 0; $i < $array->arraysize(); $i++) {
        $item = $array->arraymem($i);
        $idobject = $item->structmem('thumbId');
        $myid = $idobject->scalarval();
        $idarray[] = new XML_RPC_Value($myid);
}

print("\n\n::fetching the thumb of the item:\n\n");
$msg = new XML_RPC_Message('getItems',array(new XML_RPC_Value($authtoken, 'string'),
                                                new XML_RPC_Value(0, 'int'),
                                                new XML_RPC_Value(array(new XML_RPC_Value($myid, 'int')), 'array')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");
												

/*
print("\n\n::deleting the test album::\n\n");
$msg = new XML_RPC_Message('deleteEntityById', array(new XML_RPC_Value($authtoken, 'string'), new XML_RPC_Value($newAlbumId, 'int')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");

print("\n\n::trying to delete something we already deleted::\n\n");
$msg = new XML_RPC_Message('deleteEntityById', array(new XML_RPC_Value($authtoken, 'string'), new XML_RPC_Value($newAlbumId, 'int')));
print_r($msg->serialize() . "\n");
$res = $client->send($msg);
print_r($res->serialize() . "\n");
*/

?>
