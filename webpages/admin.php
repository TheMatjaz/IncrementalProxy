<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);
if (isset($_POST['username']) && isset($_POST['password'])) {
    $username = pg_escape_string(trim($_POST['username']));
    $password = pg_escape_string(trim($_POST['password']));
} else {
    $username = '';
    $password = '';
}
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
            <p>If you select none, the current status of all users and their domains will be listed.</p>
            <form action=\"admin_domains.php\" method=\"post\"><ul>";
            if ($success) {
                $users = $statement->fetchAll(PDO::FETCH_COLUMN, 0);
                foreach ($users as $user) {
                    echo "<li><input type='checkbox' name='users[]' value='" . $user . "'> " . $user . "</li>";
                }
                echo "</ul><div class=\"button\"><button type=\"submit\">Submit</button></div></form</body></html>";
            } else {
                echo "<h2>Database error</h2><p>An error occurred while inserting the unlock in the database.</p></body></html>";
            }
        }
    }
?>
