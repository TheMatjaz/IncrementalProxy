<?php
    $url = "http://matjaz.it/"
    $username = ""
    $helpermessage = ""
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
<html>
<head>
<title>IncrementalProxy</title>
</head>
<body>
<style>
    /* Taken from https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Forms/My_first_HTML_form */
    form {
        /* Just to center the form on the page */
        margin: 0 auto;
        width: 400px;
        /* To see the outline of the form */
        padding: 1em;
        border: 1px solid #CCC;
        border-radius: 1em;
    
    }
    form div + div {
        margin-top: 1em;
    
    }
    label {
        /* To make sure that all labels have the same size and are properly aligned */
        display: inline-block;
        width: 90px;
        text-align: right;
    
    }
    input, textarea {
        /* To make sure that all text fields have the same font settings
           By default, textareas have a monospace font */
        font: 1em sans-serif;

        /* To give the same size to all text field */
        width: 300px;
        -moz-box-sizing: border-box;
        box-sizing: border-box;

        /* To harmonize the look & feel of text field border */
        border: 1px solid #999;
    
    }
    input:focus, textarea:focus {
        /* To give a little highlight on active elements */
        border-color: #000;
    
    }
    textarea {
        /* To properly align multiline text fields with their labels */
        vertical-align: top;

        /* To give enough room to type some text */
        height: 5em;

        /* To allow users to resize any textarea vertically
           It does not work on all browsers */
        resize: vertical;
    
    }
    .button {
        /* To position the buttons to the same position of the text fields */
        padding-left: 90px; /* same size as the label elements */
    
    }
    button {
        /* This extra margin represent roughly the same space as the space
           between the labels and their text fields */
        margin-left: .5em;
    
    }
</style>
<?php
    if ($helpermessage == 'first') { ?>
<h2>Motivate your visit</h2>
<p>You are visiting this domain for the first time. Please insert your credentials and motivate your visit. You will be allowed to access this domain for now.</p>
<p>Be aware that, if your motivation is not good, you will be banned from this domain forever.</p>
<p>Please insert your credentials.</p>
<form action="/insertinlimbo.php" method="post">
    <div>
        <label for="name">Username: </label>
        <input type="text" id="name" name="user_name" value="<?php echo $username;?>"/>
    </div>
    <div>
        <label for="password">Password: </label>
        <input type="password" id="password" name="password" />
    </div>
    <div>
        <label for="domain">Domain: </label>
        <input type="url" id="domain" name="domain" value="<?php echo $domain;?>/>
    </div>
    <div>
        <label for="motivation">Motivation: </label>
        <textarea id="motivation" name="motivation"></textarea>
    </div>
    <div class="button">
        <button type="submit">Send</button>
    </div>
</form>
<?php } elseif ($helpermessage == 'denied') { ?>
<h2>The domain is blocked</h2>
<p>This domain has been blocked by the proxy administrator.</p>
<p>If you need to visit it for a specified period of time, please fill out this form.</p>
<p>Be aware that, if your motivation is not good, you will be banned from this domain forever.</p>
<p>Please insert your credentials.</p>
<form action="/unlock.php" method="post">
    <div>
        <label for="name">Username: </label>
        <input type="text" id="name" name="user_name" value="<?php echo $username;?>"/>
    </div>
    <div>
        <label for="password">Password: </label>
        <input type="password" id="password" name="password" />
    </div>
    <div>
        <label for="domain">Domain: </label>
        <input type="url" id="domain" name="domain" value="<?php echo $domain;?>/>
    </div>
    <div>
        <label for="time">Unlock length: </label>
        <input type="radio" name="unlocklength" value="1h"> 1 hour<br>
        <input type="radio" name="unlocklength" value="1w"> 1 week<br>
        <input type="radio" name="unlocklength" value="1y"> 1 year
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

