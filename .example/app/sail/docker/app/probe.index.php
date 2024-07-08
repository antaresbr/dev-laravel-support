<?php

$status = null;
$steps = 0;

while (true) {
    try {
        ob_start();
        phpinfo();
        $info = ob_get_contents();
        ob_get_clean();
        $steps++;
        sleep(1);
    }
    catch (Exception $e) {
        $status = "fail";
        break;
    }
    if ($steps >= 5) {
        $status = "success";
        break;
    }
}
echo $status;
