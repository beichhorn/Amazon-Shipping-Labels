
      //--------------------------------------------------------------------
      //
      // PURPOSE: Build JSON request file for CURL command.
      //
      // M A I N T E N A N C E   L O G
      // -----------------------------
      // BJE 07/27/2023: Created
      //
      //--------------------------------------------------------------------
       Ctl-Opt Option(*SrcStmt) Bnddir('QC2LE');

       // Prototypes
       Dcl-Pr  Entry     Extproc('BLDJSON');
         #Process      Char(6);
         #PONumber     Char(15);
         #ContainerID  Char(15);
         #ItemSeq      Char(4);
         #Quantity     Char(4);
         #Asin         Char(10);
         #Directory    Char(19);
       End-Pr;

       Dcl-Pi Entry;
         #Process      Char(6);
         #PONumber     Char(15);
         #ContainerID  Char(15);
         #ItemSeq      Char(4);
         #Quantity     Char(4);
         #Asin         Char(10);
         #Directory    Char(19);
       End-Pi;

       // Prototypes for IFS access

       Dcl-Pr    openf     Int(10)  extproc('open');
         path              Pointer  value options(*STRING);
         oflag             Int(10)  value;
         mode              Uns(10)  value options(*NOPASS);
         codepage          Uns(10)  value options(*NOPASS);
       End-Pr;

       Dcl-Pr    readf    Int(10)  extproc('read');
         fildes           Int(10)  value;
         buf              Pointer  value;
         nbyte            Uns(10)  value;
       End-Pr;

       Dcl-Pr    writef    Int(10)  extproc('write');
         fildes           Int(10)  value;
         buf              Pointer  value;
         nbyte            Uns(10)  value;
       End-Pr;

       Dcl-Pr    closef    Int(10)  extproc('close');
         fildes            Int(10)  value;
       End-Pr;

       // Constants for IFS Creation
       Dcl-C o_RDONLY        1;
       Dcl-C o_WRONLY        2;
       Dcl-C o_CREAT         8;
       Dcl-C o_TRUNC         64;
       Dcl-C o_CODEPAGE      8388608;
       Dcl-C o_TEXTDATA      16777216;
       Dcl-C o_TEXT_CREAT    33554432;

       // Constants for IFS authority
       Dcl-C RW              6;
       Dcl-C R               4;
       Dcl-C OWNER           64;
       Dcl-C GROUP           8;

       // Declare Variables
       Dcl-S path           Char(50);
       Dcl-S fd             Int(10);
       Dcl-S Data           Char(500);
       Dcl-S client_secret  Char(200);
       Dcl-S refresh_token  Char(700);
       Dcl-S client_id      Char(200);
       Dcl-S sellingParty   Char(10);
       Dcl-S shipFromParty  Char(10);

       // Declare Constants
       Dcl-C CRLF       x'0d25';
       Dcl-C ##YES     '1';

       // ------------------------------------------------------------------------------------------
       // Mainline Routine
       // ------------------------------------------------------------------------------------------

         // Open text file for reading client secret key
         path = '/home/amazon/client_secret.txt';
         fd = openf(%trim(path):O_RDONLY + O_TEXTDATA);
         readf(fd : %addr(client_secret) : %size(client_secret));
         client_secret = %trim(client_secret);
         closef(fd);

         // Open text file for reading refresh token key
         path = '/home/amazon/refresh_token.txt';
         fd = openf(%trim(path):O_RDONLY + O_TEXTDATA);
         readf(fd : %addr(refresh_token) : %size(refresh_token));
         refresh_token = %trim(refresh_token);
         closef(fd);

         // Open text file for reading client id
         path = '/home/amazon/client_id.txt';
         fd = openf(%trim(path):O_RDONLY + O_TEXTDATA);
         readf(fd : %addr(client_id) : %size(client_id));
         client_id = %trim(client_id);
         closef(fd);

         // Open text file for reading Selling Party
         path = '/home/amazon/sellingParty.txt';
         fd = openf(%trim(path):O_RDONLY + O_TEXTDATA);
         readf(fd : %addr(sellingParty) : %size(sellingParty));
         sellingParty = %trim(sellingParty);
         closef(fd);

         // Open text file for reading Ship From Party
         path = '/home/amazon/shipFromParty.txt';
         fd = openf(%trim(path):O_RDONLY + O_TEXTDATA);
         readf(fd : %addr(shipFromParty) : %size(shipFromParty));
         shipFromParty = %trim(shipFromParty);
         closef(fd);

         // Open text file for writing
         path = #Directory + '/json.txt';
         fd = openf(%trim(path):O_CREAT+O_WRONLY+O_CODEPAGE:
              RW*OWNER + RW*GROUP + R:819);

         // File needs to be closed and then reopened for data to be PC readable
         closef(fd);

         fd = openf(%trim(path):O_TEXTDATA+O_WRONLY);

         If #Process = 'LWA';
           data = '{' + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));
           data = '"grant_type":"refresh_token",' + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));
           data = '"refresh_token":' + %trim(refresh_token) + ',' + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));
           data = '"client_id":' + %trim(client_id) + ',' + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));
           data = '"client_secret":' + %trim(client_secret) + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));
           data = '}' + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));

         Endif;

         If #Process = 'RDT';
           data = '{"restrictedResources":[{"method": "POST","path": ' +
             '"/vendor/directFulfillment/shipping/2021-12-28/'
             + 'shippingLabels/{all}"}]}'
             + CRLF;
           writef(fd: %addr(data): %len(%trim(data)));
         Endif;

         If #Process = 'TRANID';
           If #ContainerID = *blanks;
             data = '{"shippingLabelRequests":[{"purchaseOrderNumber": "' +
             %trim(#PONumber) +
             '","sellingParty": {"partyId": ' + %trim(sellingParty) +
             '},"shipFromParty": ' +
             '{"partyId": ' + %trim(shipFromParty) + '}}]}' + CRLF;
           Else;
             data = '{"shippingLabelRequests":[{"purchaseOrderNumber": "' +
               %trim(#PONumber) +
               '","sellingParty": {"partyId": ' + %trim(sellingParty) + '},' +
               '"shipFromParty": {"partyId": ' + %trim(shipFromParty) + '},' +
               '"containers": [{"containerType": "package", ' +
               '"containerIdentifier": "' + %trim(#ContainerID) + '"},' +
               '"packedItems": [{"itemSequenceNumber": ' +
               %char(%int(#ItemSeq)) +
               ', "buyerProductIdentifier": "' + %trim(#Asin) + '", ' +
               '"packedQuantity": {"amount": ' +
               %char(%int(#Quantity)) + ', ' +
               '"unitOfMeasure": "Each"}}]]}]}' + CRLF;
             Endif;
             writef(fd: %addr(data): %len(%trim(data)));
         Endif;

         If #Process = 'LABEL';
           If #ContainerID = *blanks;
             data = '{"sellingParty": {"partyId": ' + %trim(sellingParty) +
             '}, ' +
             '"shipFromParty": {"partyId": ' + %trim(shipFromParty) + '}}' +
             CRLF;
           Else;
             data = '{"sellingParty": {"partyId": ' + %trim(sellingParty) +
             '}, ' +
             '"shipFromParty": {"partyId": ' + %trim(shipFromParty) + '}, ' +
             '"containers": [{"containerType": "carton", ' +
             '"containerIdentifier": "' + %trim(#ContainerID) + '",' +
             '"dimensions": { ' +
               '"length": "12",' +
               '"width": "12",'  +
               '"height": "12",' +
               '"unitOfMeasure": "IN"' +
             '},' +
               '"weight": {' +
               '"unitOfMeasure": "KG",' +
               '"value": "10"' +
             '},' +
             '"packedItems": [{"itemSequenceNumber": ' +
             // %char(%int(#ItemSeq)) +
             // ', "buyerProductIdentifier": "' + %trim(#Asin) + '", ' +
             %char(%int(#ItemSeq)) + ', ' +
             '"packedQuantity": {"amount": ' +
             %char(%int(#Quantity)) + ', ' +
             '"unitOfMeasure": "Each"}}]}]}' + CRLF;
           Endif;
           writef(fd: %addr(data): %len(%trim(data)));
         Endif;

         closef(fd);

         *INLR = ##YES;

         Return;
