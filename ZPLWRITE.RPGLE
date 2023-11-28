     FZPLSPOOLP IF   E             DISK    RENAME(ZPLSPOOLP:INPUT)
     FQSYSPRT   O    F  132        PRINTER PRTCTL(PRINTDS)

     DPRINTDS          DS            15
     D  SPACEB                 3      3
     D  SKIPB                  7      9

        Dcl-S LINE     Char(132);

     IINPUT
     I              ZPLSPOOLP                   INDATA

        Dou %eof(ZPLSPOOLP);
          Read ZPLSPOOLP;

          If not %eof(ZPLSPOOLP);
            Clear PRINTDS;

            If %subst(INDATA:1:3) <> *blanks;
              SKIPB =  %subst(INDATA:1:3);
            Else;
              SPACEB = %subst(INDATA:4:1);
            Endif;

            LINE = %subst(INDATA:5:132);
            Except DETAIL;

          Endif;

        Enddo;

        *INLR = *On;

        Return;

     OQSYSPRT   E            DETAIL
     O                       LINE               132
