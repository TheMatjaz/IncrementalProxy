<!DOCTYPE html>
<html lang="en-us">
<head>
<meta charset="utf-8"/>
<title>IncrementalProxy</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);
$users = '';
if (isset($_POST['users'])) {
    $users = $_POST['users'];
}

if ($users != '') {
    // Print the table for moderation
    $db_handle = new PDO('pgsql:dbname=squid;host=localhost', 'squid_admin', 'squidadminpostgresqlpw');
    // Get the list of domains per user from the database
    $statement = $db_handle->prepare(
    "SELECT id, username, domain, reason
    FROM incrementalproxy.vw_domains_per_user
    WHERE username IN ('" . implode("','", $users) . "')
    AND status = 'limbo'
    ORDER BY username, domain;");
    $success = $statement->execute();
    if (!$success) {
        echo "<h2>Database error</h2>
        <p>An error occurred while selecting the users from the database.</p>
        </body></html>";
        die();
    }
    if ($statement->rowCount() == 0) {
        echo "<h2>All done!</h2><p>This user has no limbo domains, everything was moderated.</p></body></html>";
        die();
    }
    echo "<h2>Choose domains to moderate</h2>
        <form action='admin_domains_moderator.php' method='post'>
        <table>
        <tr><th>ALLOW/DENY/BAN</th><th>Id</th><th>Username</th><th>Domain</th><th>Reason</th></tr>";
    $rows = $statement->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as $row) {
        echo "<tr><td>
        <input type='radio' name='moderation[" . $row['id'] . "]' value='allowed' checked='checked'>
        <input type='radio' name='moderation[" . $row['id'] . "]' value='denied'>
        <input type='radio' name='moderation[" . $row['id'] . "]' value='banned'>
        </td><td>"
        . $row['id'] . "</td><td>"
        . $row['username'] . "</td><td>"
        . $row['domain'] . "</td><td>"
        . $row['reason'] . "</td></tr>";
    }
    echo "</table>
        <div class='button'>
        <button type='submit'>Submit</button>
        </div>
        </form>";
} else {
    $db_handle = new PDO('pgsql:dbname=squid;host=localhost', 'squid_admin', 'squidadminpostgresqlpw');
    // Get the list of domains per user from the database
    $statement = $db_handle->prepare(
        "SELECT id, username, domain, status, reason, current_timestamp < unlock_end as unlocked, unlock_end
        FROM incrementalproxy.vw_domains_per_user
        ORDER BY username, domain;");
    $success = $statement->execute();
    if (!$success) {
        echo "<h2>Database error</h2>
        <p>An error occurred while selecting the users from the database.</p>
        </body></html>";
        die();
    }
    // Print the full domains_per_user table
    echo "<h2>All domains visited by each user</h2>
        <table>
        <tr><th>Id</th><th>Username</th><th>Domain</th><th>Status</th><th>Unlocked</th><th>Unlock end</th><th>Reason</th></tr>";
    $rows = $statement->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as $row) {
        echo "<tr><td>"
              . $row['id'] . "</td><td>"
              . $row['username'] . "</td><td>"
              . $row['domain'] . "</td><td>"
              . $row['status'] . "</td><td>"
              . $row['unlocked'] . "</td><td>"
              . $row['unlock_end'] . "</td><td>"
              . $row['reason'] . "</td></tr>";
    }
    echo "</table>";
}
?>
</body>
</html>

