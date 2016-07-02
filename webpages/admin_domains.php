<!DOCTYPE html>
<html lang="en-us">
<head>
<meta charset="utf-8"/>
<title>IncrementalProxy</title>
<style>
table {
    border-collapse: collapse;
    width: 100%;
}
th, td {
    text-align: left;
    padding: 8px;
}
tr:nth-child(even){background-color: #f2f2f2}
</style>
</head>
<body>
<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);
if (isset($_POST['users'])) {
    $users = $_POST['users'];
    if (empty($users)) {
        echo "
        <h2>Select some users before using this</h2><p>Go back and try again.</p>
        </body>
        </html>";
        die();
    }
} else {
    echo "
    <h2>Use the admin form</h2><a href='admin.php'>Here</a>
    </body>
    </html>";
    die();
}
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
// Print the list of users
?>
<h2>Choose domains to moderate</h2>
<form action="admin_domains_moderator.php" method="post">
<table>
<tr><th>ALLOW/DENY/BAN</th><th>Id</th><th>Username</th><th>Domain</th><th>Reason</th></tr>

<?php
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
?>
</table>
<div class="button">
    <button type="submit">Submit</button>
</div>
</form>
</body>
</html>

