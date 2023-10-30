<?

	$directory = $argv[2];
    $str = file_get_contents($directory."/response.txt");

    // Extract Content Image
	$start = strpos($str, '"content":') + 11;
	$end   = strpos($str, '"}',$start);
	
	// Decode Content Image from Base64 and Save
    $txt = substr($str, $start, $end-$start);
    $poNumber = substr($argv[1],0,9);
   	$outfile = fopen($directory . "/".trim($poNumber).".txt", "w");
    $txt = trim(base64_decode($txt));                       
    fwrite($outfile, $txt);                                 
    fclose($outfile); 
    
    // Extract Tracking Number
    $start = strpos($str, '"trackingNumber":') + 18;
	$end   = strpos($str, '",',$start);
    
	// Save Tracking Number
	$txt = substr($str, $start, $end-$start);
    $outfile = fopen($directory . "/TRACKNO.txt", "w");
    fwrite($outfile, $txt);
    fclose($outfile);
	
?>
