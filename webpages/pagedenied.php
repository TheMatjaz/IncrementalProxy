<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);
    $url = "http://matjaz.it/";
    $username = "";
    $helpermessage = "first";
    if (isset($_GET['url'])) {
        $url = $_GET['url'];
    }
    if (isset($_GET['username'])) {
        $username = $_GET['username'];
    }
    if (isset($_GET['helpermessage'])) {
        $helpermessage = $_GET['helpermessage'];
    }
    $parsed_url = parse_url($url);
    $domain = $parsed_url['host'];
?>
<!DOCTYPE html>
<html lang="en-us">
<head>
<meta charset="utf-8"/>
<title>IncrementalProxy</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
<?php
    if ($helpermessage == 'first') { ?>
<h2>Motivate your visit</h2>
<p>You are visiting this domain for the first time. Please insert your credentials and motivate your visit. You will be allowed to access this domain for now.</p>
<p>Be aware that, if your motivation is not good, you will be banned from this domain forever.</p>
<p>Please insert your credentials.</p>
<form action="insertinlimbo.php" method="post">
    <div>
        <label for="username">Username: </label>
        <input type="text" id="username" name="username" value="<?php echo $username;?>"/>
    </div>
    <div>
        <label for="password">Password: </label>
        <input type="password" id="password" name="password" />
    </div>
    <div>
        <label for="domain">Domain: </label>
        <input type="text" id="domain" name="domain" value="<?php echo $domain;?>"/>
        <input type="hidden" id="url" name="url" value="<?php echo $url;?>" />
    </div>
    <div>
        <label for="motivation">Motivation: </label>
        <textarea id="motivation" name="motivation"></textarea>
    </div>
    <div class="button">
        <button type="submit">Send</button>
    </div>
</form>
<?php } elseif ($helpermessage == 'denied' || $helpermessage == 'expired') { ?>
<h2>The domain is blocked</h2>
<p>This domain has been blocked by the proxy administrator.</p>
<p>If you need to visit it for a specified period of time, please fill out this form.</p>
<p>Be aware that, if your motivation is not good, you will be banned from this domain forever.</p>
<p>Please insert your credentials.</p>
<form action="unlock.php" method="post">
    <div>
        <label for="username">Username: </label>
        <input type="text" id="username" name="username" value="<?php echo $username;?>"/>
    </div>
    <div>
        <label for="password">Password: </label>
        <input type="password" id="password" name="password" />
    </div>
    <div>
        <label for="domain">Domain: </label>
        <input type="text" id="domain" name="domain" value="<?php echo $domain;?>"/>
        <input type="hidden" id="url" name="url" value="<?php echo $url;?>" />
    </div>
    <div>
        <label for="time">Unlock length: </label>
        <input type="radio" name="unlocklength" value="1 hour" checked="checked"> 1 hour <input type="radio" name="unlocklength" value="1 week"> 1 week <input type="radio" name="unlocklength" value="1 year"> 1 year
    </div>
    <div>
        <label for="motivation">Motivation: </label>
        <textarea id="motivation" name="motivation"></textarea>
    </div>
    <div class="button">
        <button type="submit">Send</button>
    </div>
</form>
<?php } elseif ($helpermessage == 'banned') { ?>
<h2>This domain is banned permanently</h2>
<p>This domain is forbidden for you. Contact the proxy admin at <em>dev at matjaz dot it</em> for any further info.</p>
<?php } else { ?>
<h2>An error occurred in generating this page</h2>
<p>
Username: <?php echo $username;?><br>
URL: <?php echo $url;?><br>
Domain: <?php echo $domain;?><br>
Helper message: <?php echo $helpermessage;?><br>
Contact the proxy admin at <em>dev at matjaz dot it</em> for any further info.</p>
<?php } ?>
</body>
</html>

