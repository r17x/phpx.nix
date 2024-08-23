<?php
// Access environment variables
$dbname = getenv('DBNAME');
$dbuser = getenv('DBUSER');
$dbpass = getenv('DBPASS');
$dbhost = getenv('DBHOST');
$dbport = getenv('DBPORT');

// Creating the connection string
$connectionString = "host=$dbhost port=$dbport dbname=$dbname user=$dbuser password=$dbpass";

// Connect to PostgreSQL
$conn = pg_connect($connectionString);

// Check connection
if (!$conn) {
    echo "An error occurred while connecting to the database.\n";
    echo pg_last_error($conn);
    exit;
}

echo "Connected to the database successfully!";
