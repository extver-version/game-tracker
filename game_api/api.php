<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') { http_response_code(200); exit(); }

$host = "localhost"; $user = "root"; $pass = ""; $db = "game_tracker_db";
$conn = new mysqli($host, $user, $pass, $db);
$conn->set_charset("utf8"); // PENTING: Agar mendukung karakter khusus/emoji
if ($conn->connect_error) die(json_encode(["status" => "error", "message" => "Koneksi DB gagal"]));

$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'GET') {
    $res = $conn->query("SELECT * FROM games ORDER BY id DESC");
    $data = []; 
    if ($res) {
        while($row = $res->fetch_assoc()) $data[] = $row;
    }
    echo json_encode($data);

} elseif ($method == 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $judul = $input['judul'] ?? ''; 
    $rating = (int)($input['rating'] ?? 0); 
    $platform = $input['platform'] ?? '';
    
    if(empty($judul) || empty($platform)) { 
        echo json_encode(["status" => "error", "message" => "Judul dan Platform wajib diisi"]); 
        exit(); 
    }
    
    $stmt = $conn->prepare("INSERT INTO games (judul, rating, platform) VALUES (?, ?, ?)");
    $stmt->bind_param("sis", $judul, $rating, $platform);
    
    if ($stmt->execute()) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $stmt->error]);
    }
    $stmt->close();

} elseif ($method == 'DELETE') {
    $id = $_GET['id'] ?? 0;
    if($id == 0) { echo json_encode(["status" => "error", "message" => "ID tidak ditemukan"]); exit(); }
    $stmt = $conn->prepare("DELETE FROM games WHERE id = ?");
    $stmt->bind_param("i", $id);
    if ($stmt->execute()) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => $stmt->error]);
    }
    $stmt->close();
}
$conn->close();
?>