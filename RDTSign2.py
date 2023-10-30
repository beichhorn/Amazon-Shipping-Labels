
# ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
# //                                                                                                                    //
# // Script Name = RDTSign2.py                                                                                         //
# //                                                                                                                    //
# // Author = Bernard Eichhorn (Paragon Consulting Services, Inc.)                                                      //
# // 
# // Purpose = This script is used to calculate a signature to retreive a RDT (Restricted Data Token) from Amazon       //                                                                                                                    //
#//           so that sensitive data can be received.  JSON is built to be used in a POST method.                      //                                                                                                                                                                                                  //
# //                                                                                                                    //
# ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import hashlib, hmac, sys
from datetime import date, timezone, datetime
  
# Pass in message and use secret key to generate a sha256 (Secret Hash Algorithm) binary or hex value 
def sign(key, message, binary) :
    message_bytes = hmac.new(key, bytes(message, "ascii"), digestmod=hashlib.sha256)
    if binary:
        return message_bytes.digest()
    else:
        return message_bytes.hexdigest()
                
# Generate sha256 (256 bits or 32 bytes) hash value for data
def Hash256(data):
    result = hashlib.sha256(data.strip().encode())	
    return result.hexdigest()
    
# Calculate a signature key  
def getSignatureKey(key, dateStamp, regionName, serviceName):
    kDate    = sign(bytes('AWS4' + key, "ascii"), dateStamp, True)
    kRegion  = sign(kDate, regionName, True)
    kService = sign(kRegion, serviceName, True)
    kSigning = sign(kService, 'aws4_request', True)
    return kSigning

# Values provided by Amazon
method = "POST"
service = "execute-api"
host = "sellingpartnerapi-na.amazon.com"

# Get Amazon provided region from text file
f = open("/home/amazon/region.txt", "r")
region = (f.read())
f.close()

# Get Amazon provided access key from text file
f = open("/home/amazon/access_key.txt", "r")
access_key = (f.read())
f.close()

# Get Amazon provided secret key from text file
f = open("/home/amazon/secret_key.txt", "r")
secret_key = (f.read())
f.close()

# Build JSON request for Restricted Resources
request_parameters = '{"restrictedResources":[{"method": "POST","path": "/vendor/directFulfillment/shipping/2021-12-28/shippingLabels/{all}"}]}'
	
# Generate Date and Time values
amzdate   = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
datestamp = datetime.now(timezone.utc).strftime("%Y%m%d")
	
# Build Canonical Request
canonical_uri = '/tokens/2021-03-01/restrictedDataToken'
canonical_querystring = ''
canonical_headers = "host:" + host + "\n" + "x-amz-date:" + amzdate + "\n"
signed_headers = "host;x-amz-date"
payload_hash = Hash256(request_parameters) 
canonical_request = method + "\n" + canonical_uri + "\n" + canonical_querystring + "\n" + canonical_headers + "\n" + signed_headers + "\n" + payload_hash + "\n"
	
# Create the String to Sign
algorithm = "AWS4-HMAC-SHA256"
credential_scope = datestamp + "/"+ region + "/" + service + "/" + "aws4_request"
string_to_sign = algorithm + "\n" + amzdate + "\n" + credential_scope + "\n" + Hash256(canonical_request)
	
# Calculate the Signature (signing) key
signing_key = getSignatureKey(secret_key, datestamp, region, service)
	
# Sign the string_to_sign using the signing_key
signature = sign(signing_key, string_to_sign, False)

# Save the Signature and Date in text file 
directory = sys.argv[2]
with open(directory.strip() + "/SIGNATURE.txt", "w") as f:
    f.write(amzdate.strip() + "\n")
    f.write(signature.strip())
