import sys, base64, os, codecs
 
poNumber  = sys.argv[1]
directory = sys.argv[2] 

# Delete Files if already existing
if os.path.exists(directory.strip() + "/" + poNumber.strip() + ".txt"):
    os.remove(directory.strip() + "/" + poNumber.strip() + ".txt")

if os.path.exists(directory.strip() + "/TRACKNO.txt"):
    os.remove(directory.strip() + "/TRACKNO.txt")    

base64_string = " "
txt           = " "

with open(directory + "/response.txt", "r") as g:
     str = g.read()

# Extract Label(s)
start = str.find('"content":') + 11
end   = 0
while start > 0 and start > end:
    end   = str.find('"}', start) 
    txt   = str[start:end]
    # Label text is in Base64 format, need to decode
    txt_bytes = txt.encode()
    base64_bytes   = base64.b64decode(txt_bytes)
    base64_string  = base64_bytes.decode(encoding='utf-8', errors='ignore')
    
    # Save Label(s)
    with open(directory.strip() + "/" + poNumber.strip() + ".txt", "a") as f:
        f.write(base64_string)

    # Keep searching 
    start = str.find('"content":', end) + 11 

# Extract Tracking Number(s)
start = str.find('"trackingNumber":') + 18
end   = 0
txt   = " "
while start > 0 and start > end:
    end   = str.find('",', start);
    txt   = str[start:end] + "\n"

    # Save Tracking Number(s)
    with open(directory.strip() + "/TRACKNO.txt", "a") as f:
      f.write(txt)

    # Keep searching
    start = str.find('"trackingNumber":', end) + 18