import sys, base64, codecs
 
poNumber  = sys.argv[1]
directory = sys.argv[2] 

with open(directory + "/response.txt", "r") as g:
     str = g.read()

# Extract Label
start = str.find('"content":') + 11
end   = str.find('"}', start)
txt   = str[start:end]

# Label text is in Base64 format, need to decode
txt_bytes = txt.encode()
base64_bytes = base64.b64decode(txt_bytes)
print(base64_bytes)
base64_string = base64_bytes.decode(encoding='utf-8', errors='ignore')

# Save Label
with open(directory.strip() + "/" + poNumber.strip() + ".txt", "w") as f:
    f.write(base64_string)

# Extract Tracking Number
start = str.find('"trackingNumber":') + 18
end   = str.find('",', start);
txt   = str[start:end]

# Save Tracking Number
with open(directory.strip() + "/TRACKNO.txt", "w") as f:
    f.write(txt)


        
        
