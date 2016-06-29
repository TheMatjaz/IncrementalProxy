<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);
// Fetch POST parameters
$username = pg_escape_string(trim($_POST['username']));
$password = pg_escape_string(trim($_POST['password']));
$domain = pg_escape_string(trim($_POST['domain']));
$motivation = pg_escape_string(trim($_POST['motivation']));
$url = pg_escape_string(trim($_POST['url']));
$authenticated = FALSE;
$response = "";

// Create database connection handle
$db_handle = new PDO('pgsql:dbname=squid;host=localhost', 'squid', 'squidpostgresqlpw');

// Verify the user actually exists
$statement = $db_handle->prepare("SELECT TRUE AS authenticated FROM incrementalproxy.vw_users WHERE username = :username AND password = :password;");
$statement->execute(array('username' => $username, 'password' => $password));
if ($row = $statement->fetch(PDO::FETCH_ASSOC)) {
    $authenticated = ($row['authenticated'] == TRUE);
}

if (!$authenticated) {
    $response = "</head><body><h2>Login failed</h2><p>Wrong username or password. Go back and try again.</p>";
} else {
    // Insert domain into limbo in the database
    $statement = $db_handle->prepare("INSERT INTO incrementalproxy.vw_domains_per_user (username, domain, status, reason) VALUES (:username, :domain, 'limbo', :motivation);");
    $success = $statement->execute(array('username' => $username, 'domain' => $domain, 'motivation' => $motivation));
    if ($success) {
        $response = "<meta http-equiv=\"refresh\" content=\"2;URL='" . $url . "'\" /></head><body><h2>Domain in limbo</h2><p>The <a href=\"" . $url . "\">requested domain</a> is now in limbo status. You may go on it but will be moderated by the proxy administrator for future usage.</p>";
    } else {
        $response = "</head><body><h2>Database error</h2><p>An error occurred while inserting your request in the database.</p>";
    }
}
?>
<!DOCTYPE html>
<html lang="en-us">
<head>
<meta charset="utf-8"/>
<title>IncrementalProxy</title>
<?php echo $response; ?>
</body>
</html> 

