<?php
// Fetch POST parameters
$username = pg_escape_string(trim($_POST['username']));
$password = pg_escape_string(trim($_POST['password']));
$domain = pg_escape_string(trim($_POST['domain']));
$motivation = pg_escape_string(trim($_POST['motivation']));
$unlocklength = pg_escape_string(trim($_POST['unlocklength']));
$authenticated = FALSE;
$response = "";

// Create database connection handle
$db_handle = new PDO('pg:dbname=squid;host=localhost;charset=utf8', 'squid', 'squidpostgresqlpw');

// Verify the user actually exists
$statement = $pdo->$prepare("SELECT TRUE AS authenticated FROM incrementalproxy.vw_users WHERE username = :username AND password = :password;");
$statement->execute(array('username' => $usernname, 'password' => $password));
if ($row = $statement->fetch(PDO::FETCH_ASSOC)) {
    $authenticated = ($row['authenticated'] == TRUE);
}

if (!$authenticated) {
    $response = "</head><body><h2>Database error</h2><p>Wrong username or password. Go back and try again.</p>";
} else {
    // Insert unlock into database
    $statement = $pdo->prepare("INSERT INTO incrementalproxy.vw_domain_unlocks (username, domain, reason, unlock_start, unlock_end) VALUES (:username, :domain, :motivation, current_timestamp, current_timestamp + ':unlocklength'::interval);");
    $success = $statement->execute(array('username' => $usernname, 'domain' => $domain, 'motivation' => $motivation, 'unlocklength' => $unlocklength));
    if ($success) {
        $response = "<meta http-equiv=\"refresh\" content=\"1;URL='" . $url . " /></head><body><h2>Domain in limbo</h2><p>The <a href=\"" . $url . "\">requested domain</a> is unlocked for a limited amount of time.</p>";
    } else {
        $response = "</head><body><h2>Database error</h2><p>An error occurred while inserting the unlock in the database.</p>";
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<title>IncrementalProxy</title>
<?php echo $response; ?>
</body>
</html>
