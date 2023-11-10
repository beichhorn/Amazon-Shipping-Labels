
      //--------------------------------------------------------------------
      //
      // PURPOSE: Build command line file for CURL command.
      //
      // M A I N T E N A N C E   L O G
      // -----------------------------
      // BJE 07/27/2023: Created
      //
      //--------------------------------------------------------------------
       Ctl-Opt Option(*SrcStmt) Bnddir('QC2LE');

       // Prototypes
       Dcl-Pr  Entry     Extproc('BLDCMDLINE');
         #Token       Char(10000);
         #TransID     Char(100);
         #Process     Char(6);
         #PONumber    Char(15);
         #Directory   Char(19);
       End-Pr;

       Dcl-Pi Entry;
         #Token       Char(10000);
         #TransID     Char(100);
         #Process     Char(6);
         #PONumber    Char(15);
         #Directory   Char(19);
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
       Dcl-S path        Char(50);
       Dcl-S fd          Int(10);
       Dcl-S Data        Char(10000);
       Dcl-S start       Int(10);
       Dcl-S end         Int(10);
       Dcl-S x           Timestamp;
       Dcl-S y           Timestamp;
       Dcl-S DateStamp   Char(16);
       Dcl-S Date8       Char(8);
       Dcl-S Signature   Char(100);
       Dcl-S Access_key  Char(25);
       Dcl-S Region      Char(15);
       Dcl-S l           Int(10);

       // Declare Constants
       Dcl-C CRLF       x'0d25';
       Dcl-C ##YES     '1';

       // ------------------------------------------------------------------------------------------
       // Mainline Routine
       // ------------------------------------------------------------------------------------------

         // Get Signature from text file
         If #Process <> 'LWA' and #Process <> 'PDF';
           path = #Directory + '/SIGNATURE.txt';
           fd = openf(%trim(path):o_RDONLY+o_TEXTDATA);

           // Read Data from text file
           readf(fd: %addr(data): %size(data));
           DateStamp = %subst(data:1:16);
           Signature = %subst(data:18:%len(Signature) - 17);
           closef(fd);
           Date8 = %subst(DateStamp:1:8);
         Endif;

         // Get Access Key from text file
         If #Process <> 'LWA' and #Process <> 'PDF';
           path = '/home/amazon/access_key.txt';
           fd = openf(%trim(path):o_RDONLY+o_TEXTDATA);
           readf(fd: %addr(data): %size(data));
           closef(fd);
           l = %len(%trim(data)) - 4;
           Access_key = %subst(data:2:l);
         Endif;

          // Get Region from text file
         If #Process <> 'LWA' and #Process <> 'PDF';
           path = '/home/amazon/region.txt';
           fd = openf(%trim(path):o_RDONLY+o_TEXTDATA);
           readf(fd: %addr(data): %size(data));
           closef(fd);
           l = %len(%trim(data)) - 4;
           Region = %subst(data:2:l);
         Endif;

         path = #Directory + '/cmdline.txt';

         fd = openf(%trim(path):O_CREAT+O_WRONLY+O_CODEPAGE:
              RW*OWNER + RW*GROUP + R:819);

         // File needs to be closed and then reopened for data to be PC readable
         closef(fd);

         fd = openf(%trim(path):O_TEXTDATA+O_WRONLY);

         Select;

           When #Process = 'LWA';
             data = '--url "https://api.amazon.com/auth/o2/token"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '--insecure' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '--verbose' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Accept: */*"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Content-Type: application/json"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Connnection: keep-alive"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '-d @' + #Directory + '/json.txt' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '-o ' + #Directory + '/RESPONSE.txt' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));

           When #Process = 'PDF';
             data = 'url = "http://api.labelary.com/v1/printers/8dpmm'
              + '/labels/4x6/0/"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '--insecure' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Accept: application/pdf"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '-d @' + #Directory + '/' + %trim(#PONumber) + '.txt'
               + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '-o ' + '/home/amazon/PDF/' + %trim(#PONumber) + '.pdf '
               + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));

           Other;

             Select;
               When #Process = 'RDT';
                 data = 'url = "https://sellingpartnerapi-na.amazon.com/tokens'
                   + '/2021-03-01/restrictedDataToken"' + CRLF;
                When #Process = 'TRANID';
                  data = 'url = "https://sellingpartnerapi-na.amazon.com/vendor'
                    + '/directFulfillment/shipping/v1/shippingLabels"' + CRLF;
                When #Process = 'STATUS';
                  data = 'url = "https://sellingpartnerapi-na.amazon.com/vendor'
                    + '/directFulfillment/transactions/v1/transactions/' +
                    %trim(#TransID) + '"' + CRLF;
                When #Process = 'LABEL';
                  data = 'url = "https://sellingpartnerapi-na.amazon.com/vendor'
                    + '/directFulfillment/shipping/2021-12-28/shippingLabels/' +
                    %trim(#PONumber) + '"' + CRLF;
             Endsl;

             writef(fd: %addr(data): %len(%trim(data)));
             data = '--insecure' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = '--verbose' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Accept: */*"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Content-Type: application/json"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Connnection: keep-alive"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             Clear data;
             data = 'header = "Authorization: AWS4-HMAC-SHA256 ' +
                    'Credential=AKIAU7UEZ2MICAXSSBXC/' + Date8 +
                    '/us-east-1/execute-api/aws4_request, ' +
                    'SignedHeaders=host;x-amz-date,' +
                    'Signature=' + %trim(Signature) + '"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "Host: sellingpartnerapi-na.amazon.com"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "x-amz-access-token: ' + %trim(#Token) + '"'
               + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             data = 'header = "x-amz-date: ' + %trim(DateStamp) + '"' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));
             If #Process = 'RDT' or #Process = 'TRANID' or #Process = 'LABEL';
               data = '-d @' + #Directory + '/json.txt' + CRLF;
               writef(fd: %addr(data): %len(%trim(data)));
             Endif;
             data = '-o ' + #Directory + '/RESPONSE.txt' + CRLF;
             writef(fd: %addr(data): %len(%trim(data)));

         Endsl;

         closef(fd);

         *INLR = ##YES;

         Return;
