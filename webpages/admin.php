<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);
    $username = pg_escape_string(trim($_POST['username']));
    $password = pg_escape_string(trim($_POST['password']));
?>
<!DOCTYPE html>
<html lang="en-us">
<head>
<meta charset="utf-8"/>
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
    if ($username == '' && $password == '') {
    // Show the login form
?>
        <h2>Administration panel login</h2>
        <form action="admin.php" method="post">
            <div>
                <label for="username">Username: </label>
                <input type="text" id="username" name="username"/>
            </div>
            <div>
                <label for="password">Password: </label>
                <input type="password" id="password" name="password" />
            </div>
            <div class="button">
                <button type="submit">Login</button>
            </div>
        </form>
<?php 
    } else {
        // Try to verify the credentials by logging into the database
        $authenticated = TRUE;
        try {
            $db_handle = new PDO('pgsql:dbname=squid;host=localhost', $username, $password);
        } catch (PDOException $exception) {
            $authenticated = FALSE;
        }
        if (!$authenticated) {
            // Login failure
            echo "<h2>Login failed</h2><p>Wrong username or password. Go back and try again.</p></body></html>";
        } else {
            // Login successfull
            // Get the list of users from the database
            $statement = $db_handle->prepare("SELECT username FROM incrementalproxy.vw_users;");
            $success = $statement->execute();
            // Print the list of users
            echo "<h2>Choose users to admin</h2>
            <form action=\"admin_domains.php\" method=\"post\"><ul>";
            if ($success) {
                while ($statement->rowCount() > 0) {
                    $user = $statement->fetch(PDO::FETCH_COLUMN, 0);
                    echo "<li><input type='checkbox' name='users[]' value='" . $user . "'> " . $user . "</li>";
                }
                echo "</ul><div class=\"button\"><button type=\"submit\">Submit</button></div></form</body></html>";
            } else {
                echo "<h2>Database error</h2><p>An error occurred while inserting the unlock in the database.</p></body></html>";
            }
        }
    }
?>
