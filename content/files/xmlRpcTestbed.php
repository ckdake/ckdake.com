<?PHP
/*
 * $RCSfile: xmlRpcTestbed.php,v $
 *
 * Gallery - a web based photo album viewer and editor
 * Copyright (C) 2000-2005 Bharat Mediratta
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA  02110-1301, USA.
 */
/**
 * @version $Revision: 1.36 $ $Date: 2005/08/23 03:49:04 $
 * @package GalleryCore
 * @author John Kelley <john (at) kelley {dot} ca>
 */
 
session_start();
require_once 'XML/RPC.php';
$isError = 0;
$errorMsg = "";
$xmlRpcResponse = 0;
//do something if we've been posted a query
if (isset($_POST['action']) && $_POST['action'] == "sendQuery") {
    if (isset($_POST['rpcHost']))
	$_SESSION['rpcHost'] = $_POST['rpcHost'];
    if (isset($_POST['rpcUrl']))
	$_SESSION['rpcUrl'] = $_POST['rpcUrl'];

    if (!isset($_SESSION['rpcHost'])) {
        $isError = 1;
	$errorMsg += 'An XMLRPC Host must be specified\n';
    }
    if (!isset($_SESSION['rpcUrl'])) {
	$isError = 1;
	$errorMsg += 'An XMLRPC URL must be specified\n';
    }
    if (!isset($_POST['rpcMethod'])) {
	$isError = 1;
	$errorMsg += 'An XMLRPC Method must be specified\n';
    }
    //If we don't have any errors actually construct and send the query
    if ($_SESSION['isError'] == 0) {
        $xmlRpcClient=new XML_RPC_Client($_SESSION['rpcUrl'], $_SESSION['rpcHost']);
        if (isset($_POST['debugOn']))
	    $xmlRpcClient->setDebug(1);
	$params = array();
	if (substr($_POST['rpcMethod'],0, 7) != "system.")
	    array_push($params, new XML_RPC_Value($_SESSION['rpcSession'], 'string'));
	foreach($_POST['rpcVars'] as $rpcVar)
	    if ($rpcVar != null)
		array_push($params, new XML_RPC_Value($rpcVar));
	$msg = new XML_RPC_MESSAGE($_POST['rpcMethod'], $params);
	$xmlRpcResponse = $xmlRpcClient->send($msg);
	if ($_POST['rpcMethod'] == 'system.listMethods') {
	    if (!$xmlRpcResponse->faultCode()) {
		$_SESSION['rpcMethods'] = array();		
		$val = $xmlRpcResponse->value();
	        $data = XML_RPC_decode($val);
		foreach($data as $method) 
		    array_push($_SESSION['rpcMethods'], $method);
	    }
	} else if ($_POST['rpcMethod'] == 'remoteprotocol.login') {
	    if (!$xmlRpcResponse->faultCode()) {
		$val = $xmlRpcResponse->value();
                $data = XML_RPC_decode($val);
		$_SESSION['rpcSession'] = $data['authToken'];
	    }
	}
    }
}
?>
<html>
<head><title>XMLRPC Testbed</title></head>
<body>
<form method="POST" action="xmlRpcTestbed.php">
<input type="hidden" name="action" value="sendQuery">
<table bgcolor="#BBBBBB">
<tr>
    <td>Server</td><td><input type="text" name="rpcHost" value="<?PHP if(!isset($_SESSION['rpcHost']))
    echo "pics.kelley.ca"; else echo $_SESSION['rpcHost']; ?>"></td>
    <td>Path</td><td><input type="text" name="rpcUrl" size="50" value="<?PHP if(!isset($_SESSION['rpcUrl']))
    echo "/main.php?g2_view=remoteprotocol.XmlRpc"; else echo $_SESSION['rpcUrl']; ?>"></td>
</tr>
<tr>
    <td>Method</td><td><select name="rpcMethod">
    <?PHP
    if (!isset($_SESSION['rpcMethods']) || count($_SESSION['rpcMethods']) == 0)
	echo "<option>system.listMethods</option>";
    else
        foreach ($_SESSION['rpcMethods'] as $method)
	    if ($method == $_POST['rpcMethod'])
		echo "<option SELECTED>$method</option>";
	    else
		echo "<option>$method</option>";
    ?>
    </select></td>
    <td colspan=2><input type="checkbox" name="debugOn" <? if (isset($_POST[debugOn]))
    echo"CHECKED";?>>Debug output </td>
</tr>
<tr>
    <td>Arg1</td><td><input type="text" name="rpcVars[0]"></td>
    <td>Arg2</td><td><input type="text" name="rpcVars[1]"></td>
</tr>
<tr>
    <td>Arg3</td><td><input type="text" name="rpcVars[2]"></td>
    <td>Arg4</td><td><input type="text" name="rpcVars[3]"></td>
</tr>
<tr>
    <td colspan=2 align=center><input type="submit"></td>
</tr>
<tr>
    <td colspan=4>Instructions: Enter your servername and path to xmlrpc handler then submit to get
    a list of available functions. Select remoteprotocol.login and provide your username in arg1 and
    password in arg2 then submit to login. The testbed will now automatically prepend your session
    ID to all subsequent function calls.</td>
</tr>
</table>
</form>
<br />
<?PHP
    if($isError == 1) {
	echo <<< EOHTML
<table width="100%" align="center" bgcolor="#FF9999">
<tr><td><strong>Error!</strong></td></tr>
<tr><td><pre>$errorMsg</pre></td></tr>
</table>
EOHTML;
    }
?>
<table width="100%" align="center" bgcolor="#9999FF">
<tr><td><strong>Result:</strong></td></tR>
<tr><td>
<pre>
<?PHP

if($xmlRpcResponse != null) {
    if($xmlRpcResponse->faultCode()) {
        echo 'Fault Code: '.$xmlRpcResponse->faultCode()."\n";
	echo 'Fault Reason: '.$xmlRpcResponse->faultString()."\n";
    } else {
        $val = $xmlRpcResponse->value();
        $data = XML_RPC_decode($val);
        print_r($data);
    }
}
?>
</pre>
</td></tr>
</table>
</body>
</html>
