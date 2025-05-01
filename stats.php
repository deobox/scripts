<?php
// Collect data every 10 mins ### Crontab ### */10 * * * *  /root/bin/stats.sh &>/dev/null;
// echo "$(date +'%d/%b/%Y,%H:%M'),$visits,$cache,$vrp1,$vrp2" >> "$csvfile";
// echo "$(date +'%d/%b/%Y,%H:%M'),$(awk 'NR==1 {print $2}' /proc/stat),$(awk '/Active:/ {print $2}' /proc/meminfo),$(awk '{print $2}' /proc/loadavg),$(wc -l < /proc/net/tcp)" >> "$syscsvfile";

// include('stats.header.php');
if (!in_array($_SERVER['REMOTE_ADDR'], ['127.0.0.1', '127.0.0.2', '127.0.0.3'])) { die("Web Stats Access Denied"); }
$csvfile='/run/httpd/www.csv'; if (!file_exists($csvfile)) { die("Sorry web data is missing"); }
$syscsvfile='/run/httpd/sys.csv'; if (!file_exists($syscsvfile)) { die("Sorry system data is missing"); }

$outfile = str_replace(".php", ".png", basename(__FILE__));
 if (file_exists(getcwd().'/'.'arial.ttf')) { $MyFont = getcwd().'/'.'arial.ttf'; } else { die("Sorry system font is missing"); }

// Load CSV data into arrays
$csv = array_map('str_getcsv', file("$syscsvfile"));

// Get the last 144 rows - 24 hours with data every 10 mins
$csv = array_slice($csv, -145);

$labels = [];
$values = [];

// Parse the CSV and populate data
foreach ($csv as $index => $row) {
    if ($row[0] !== $previousValue) {
        $labels[] = strtoupper(str_replace('/', '-', substr($row[0], 0, -5)));  // Add day when it changes
        $previousValue = $row[0];  // Update previous value
    }
    else {
        $labels[] = $row[1];  // Time Only
    }
    $values[] = $row[5];  // Value
}

// Image dimensions
$width = 1500;
$height = 300;

// Create image
$image = imagecreatetruecolor($width, $height);

// Define colors
$backgroundColor = imagecolorallocate($image, 240, 240,240);  // White Bckground
$lineColor = imagecolorallocate($image, 255, 0, 0);  // Red for the main line
$textColor = imagecolorallocate($image, 0, 80, 0);  // Green for text labels
$gridColor = imagecolorallocate($image, 220, 220, 220);  // Pale black light gray grid lines
$labelColor = imagecolorallocate($image, 0, 0, 100);  // Blue for data labels
$LegendColor = imagecolorallocate($image, 0, 0, 100);  // Blue for Bottom Line text

// Fill background
imagefill($image, 0, 0, $backgroundColor);

// Draw Frame
imagerectangle($image, 0, 0, ($width - 1), ($height - 1), imagecolorallocate($image, 100, 100, 100));

// Graph area
$padding = 50;
$spacing = ($width - 2 * $padding) / (count($labels) - 1);
$maxValue = max($values);

// Draw axes
imageline($image, $padding, $height - $padding, $width - $padding, $height - $padding, $lineColor);  // X-axis
imageline($image, $padding, $height - $padding, $padding, $padding, $lineColor);  // Y-axis

// Draw horizontal grid lines
$gridStep = $maxValue / 5;
for ($i = 0; $i <= 5; $i++) {
    $y = $height - $padding - ($i * $gridStep / $maxValue) * ($height - 2 * $padding);
    imageline($image, $padding, $y, $width - $padding, $y, $gridColor);  // Horizontal grid lines
}

// Draw vertical grid lines
for ($i = 0; $i < count($values); $i++) {
    $x = $padding + $i * $spacing;
    imageline($image, $x, $padding, $x, $height - $padding, $gridColor);  // Vertical grid line
}

// Dashed line style for the data points line
$dashPattern = array(5, 5);  // 5px line, 5px space
imagesetstyle($image, $dashPattern);

// Plot data points and draw lines
$prevX = $padding;
$prevY = $height - $padding - ($values[0] / $maxValue) * ($height - 2 * $padding);
for ($i = 1; $i < count($values); $i++) {
    $x = $padding + $i * $spacing;
    $y = $height - $padding - ($values[$i] / $maxValue) * ($height - 2 * $padding);
    imageline($image, $prevX, $prevY, $x, $y, $lineColor);
    $prevX = $x;
    $prevY = $y;
    // Add data label next to the data point
    // imagestring($image, 2, $x + 5, $y - 10, round($values[$i], 2), $labelColor);
    // imagestring($image, 2, $x, $height - 30, round($values[$i], 2), $lineColor);
    imagettftext($image, 7, 90, $x, 45, $LegendColor, $MyFont, round($values[$i], 1));
}

// Calculate average min and max values
$average = array_sum($values) / count($values); 
$minValue = min($values);  // Minimum value
$maxValue = max($values);  // Maximum value
$infoText = " | Avg: ". round($average, 2) ." | Min: ". round($minValue, 2) ." | Max: ". round($maxValue, 2);

// Print Title
$title = "TCP Connections for last 24 hours".$infoText;
$titleWidth = imagefontwidth(5) * strlen($title);  // Calculate the width of the title based on font size
$titleX = ($width - $titleWidth) / 2;  // Center the title
//imagestring($image, 4, $titleX, 10, $title, $LegendColor);
imagestring($image, 4, $titleX, $height - 25, $title, $LegendColor);

// Draw X-axis labels (without rotation for simplicity)
$font = 2;  // Built-in font size for X-axis labels
foreach ($labels as $i => $label) {
  // print every second iteration
  if ($i % 6 == 0) {
    $x = $padding + $i * $spacing;
    imagestring($image, $font, $x - (imagefontwidth($font) * strlen($label) / 2), $height - $padding + 5, $label, $textColor);
  }
}

// Draw Y-axis labels (values)
$step = $maxValue / 5;
for ($i = 0; $i <= 5; $i++) {
    $y = $height - $padding - ($i * $step / $maxValue) * ($height - 2 * $padding);
    imagestring($image, $font, $padding - 35, $y - 10, (int)($i * $step), $textColor);
}

// Save the image to a file
imagepng($image, $outfile);  // Save to file

// Clean up
imagedestroy($image);
?>
<img src='<?php echo basename($outfile); ?>' alt='Graph Last 24 hours' /><br>

