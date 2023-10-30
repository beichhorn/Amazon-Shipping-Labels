
<?php

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
// Script Name = LABELSign.php                                                                                        //
//                                                                                                                    //
// Author = Bernard Eichhorn (Paragon Consulting Services, Inc.)                                                      //
//                                                                                                                    //
// Purpose = This script is used to calculate a signature to retreive the shipping labels to print.                   //                                                                                       //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // Pass in message and use secret key to generate a sha256 (Secret Hash Algorithm) binary or hex value. 
	function sign($key, $message, $binary) { 
     return hash_hmac('sha256', $message, $key, $binary);
  }
    
  // Generate sha256 (256 bits or 32 bytes) hash value for data
  function Hash256 ($data){
     return hash( 'sha256' , $data);
  }
    
  // Calculate a signature key  
 	function getSignatureKey($key, $dateStamp, $regionName, $serviceName) {
		 $kDate    = sign('AWS4'.$key, $dateStamp, true);
		 $kRegion  = sign($kDate, $regionName, true);
		 $kService = sign($kRegion, $serviceName, true);
		 $kSigning = sign($kService, 'aws4_request', true);
		 return $kSigning;
	}

  // Values provided by Amazon
	$method = "POST";
	$service = "execute-api";
	$host = "sellingpartnerapi-na.amazon.com";
	$region = "us-east-1";
	$access_key = "AKIAXILDA5U7KB6ZMIJQ";
	$secret_key = "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";
	
	// Generate Date and Time values
	$amzdate   = gmdate('Ymd\THis\Z', time());
	$datestamp = gmdate('Ymd', time());
	
	// Build Canonical Request
  $poNumber  = substr($argv[1],0,9);
    $request_parameters = '{"sellingParty": {"partyId": "YORAL"},"shipFromParty": {"partyId": "ACLF"}}'; 
	$canonical_uri = "/vendor/directFulfillment/shipping/2021-12-28/shippingLabels/".trim($poNumber);
	$canonical_querystring = ""; 
	$canonical_headers = "host:".$host."\n"."x-amz-date:".$amzdate."\n";
	$signed_headers = "host;x-amz-date";
	$payload_hash = Hash256($request_parameters);  
	$canonical_request = $method."\n".$canonical_uri."\n".$canonical_querystring."\n".$canonical_headers."\n".$signed_headers."\n".$payload_hash;
	
  // Create the String to Sign
 	$algorithm = "AWS4-HMAC-SHA256";
	$credential_scope = $datestamp."/".$region."/".$service."/"."aws4_request";
	$string_to_sign = $algorithm."\n".$amzdate."\n".$credential_scope."\n".Hash256($canonical_request);
	
	// Calculate the Signature (signing) key
	$signing_key = getSignatureKey($secret_key, $datestamp, $region, $service);
	
 // Sign the string_to_sign using the signing_key
	$signature = sign($signing_key, $string_to_sign, false);

  // Save the Signature and Date in text file 
  $directory = $argv[2];	
  $outfile = fopen($directory . "/SIGNATURE.txt", "w");
  $txt = trim($amzdate)."\n";
  fwrite($outfile, $txt);
  $txt = trim($signature);
  fwrite($outfile, $txt);
  fclose($outfile);

?>
