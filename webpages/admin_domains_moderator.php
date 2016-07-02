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
if (isset($_POST['moderation'])) {
    $moderations = $_POST['moderation'];
    if (empty($moderations)) {
        echo "
        <h2>Moderate before using this</h2><p>Go back and try again.</p>
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
// Update the rows
$statement = $db_handle->prepare("
    UPDATE incrementalproxy.vw_domains_per_user
    SET status = :status
    WHERE id = :id ;");
echo "<ul>";
foreach($moderations as $id => $status) {
    $success = $statement->execute(array("status" => $status, "id" => $id));
    if (!$success) {
        echo "</ul><h2>Database error</h2>
        <p>An error occurred while updating the moderated domain in the database. Domains id: " . $id . "</p></body></html>";
        die();
    } else {
        echo "<li>" . $id . " is now " . $status . "</li>";
    }
}
echo "</ul></body></html>";
// Print the list of users
?>
