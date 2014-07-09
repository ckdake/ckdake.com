<html>
<head>
	<title>Mall Directory</title>
	<link rel="stylesheet" type="text/css" href="style.css" title="Default Style" />
</head>
<body>
<div align="center">
<table cellpadding="0" cellspacing="0">
<?php
	
	global $page, $previous, $previous2, $previous3;

	$nobackto = false;
	$page = $_GET["page"];
	$previous = $_GET["prev"];
	$previous2 = $_GET["prev2"];
	$previous3 = $_GET["prev3"];

	function echoURL($destination) {
		global $page, $previous, $previous2, $previous3;
		$url =  "window.location='?page=".$destination."&prev=".$page;
		if ($previous) {
			$url .= "&prev2=".$previous;
			if ($previous2) {
				$url .= "&prev3=".$previous2;
			}
		}
		$url .= "';";
		echo $url;
	}

	if ($page) {
		include("content/".$page.".html");
		if ($page != "front") {
			if (!($previous) && $page) {
				if ($page == "Categories") {
					$previous = "Alphabetical";
				$nobackto = true;
				} else if ($page == "Alphabetical") {
					$previous = "Categories";
					$nobackto = true;
				}
		}
		if (preg_match("(store)",$page)) {
?>
<tr>
	<td class="cbutton color7" onclick="alert('beamed to mobile device');"><table class="inner"><tr><td><img src="img/beam.png" /></td><td>Beam to Mobile Device</td></tr></table></td>
	<td class="cbutton color7" onclick="alert('please take your printout');"><table class="inner"><tr><td><img src="img/print.png" /></td><td>Print Directions</td></tr></table></td>
</tr>
<?php
		}
?>
<tr>
	<td class="color7 cbutton" onclick="window.location='?page=front';"><table class="inner"><tr><td><img src="img/home.png" /></td><td>Start Over</td></tr></table></td>
	<td class="color7 cbutton" onclick="window.location='?page=<?php 
		echo $previous; 
		if ($previous2) {
			echo "&prev=".$previous2;
			if ($previous3) {
				echo "&prev2=".$previous3;
			}
		}
	?>';"><table class="inner"><tr><td>
	<?php 	
		if (!($nobackto)) {
?><img style="float: left; padding-right: 5px;" src="img/back.png" /></td><td><?php
			echo "Back to ";
		}
		echo preg_replace("/_/"," ",$previous);
	}
	?></td></tr></table></td>
</tr>
<?php } else {
		include("content/front.html");
	}
?>

</table>
</div>
</body>
</html>
