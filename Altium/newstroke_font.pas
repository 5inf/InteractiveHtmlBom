function visText(text: TString):  TString;
var
  i: Integer;
begin
  for i:= 0 to Length(text)  do
  begin
       usedChars.Add(text[i]);
       //ShowMessage(text[i]);
  end;
  //ShowMessage(usedChars.ToString()+'C:'+IntToStr(usedChars.count));
  Result:=Text;
end;

function parseNewstrokeData(data:TString):TString;
const
     STROKE_FONT_SCALE = 1.0/41.0;
     FONT_OFFSET = -10.0;
var
   i: Integer;
   w: TString;
   l: TString;
   line:TString;
   glyph_x: Float;
   glyph_width: Float;
begin
    //ShowMessage(data+#13#10+'ord['+IntToStr(ord(data[i]))+','+IntToStr(ord(data[i+1]))+']chars:'+data[i]+','+data[i+1]);
    //ShowMessage(data);
    //ShowMessage(STROKE_FONT_SCALE);
    //https://docs.kicad-pcb.org/doxygen/classKIGFX_1_1STROKE__FONT.html
    //There is an additional +1 on each index, because of pascal/delphys string indexing. The first character ist as index 1 not 0.
    line:='';
    l:='';
    for i:=0 to (Length(data))-1 do
    begin
         if(i<2) then
         begin
             glyph_x := (ord(data[i+1])-ord('R'))*STROKE_FONT_SCALE;
             glyph_width := (ord(data[i+1+1])-ord(data[i+1]))* STROKE_FONT_SCALE;
         end
         else if((data[i+1]=' ') and (data[i+1+1]='R') and i>1)then
         begin
             l:= l+'['+removeLastComma(line)+'],';
             line:='';
         end else {if(i>2) then}
         begin
             line:= line + '[';
             line:= line + FloatToStr( ((ord(data[i+1]) - ord('R'))) * STROKE_FONT_SCALE - glyph_x )    ;
             line:= line + ',';
             line:= line + FloatToStr( ((ord(data[i+1+1]) - ord('R')) + FONT_OFFSET ) * STROKE_FONT_SCALE );
             line:= line + '],';
         end;
         i:=i+1;    //together with the for loop --> i := i+2
    end;
    if(Length(line)>0) then
    begin
        l:= l+'['+removeLastComma(line)+'],';
    end;

    Result:='{"l":['+removeLastComma(l)+'],"w":'+FloatToStr(glyph_width)+'},';
    //ShowMessage(l);

end;

function parse_font_char(char: char): TString;
var
  json_char:TString;
begin
  json_char:='';
  if((ord(char)<20) )then
  begin
  end
  else if ((ord(char)-20 > 128 )) then //128 is the hardcoded lenght of our current newstroke font array. The length operator seems not to work in Alitum.
  begin
       json_char:='"'+char+'":'+removeLastComma(parseNewStrokeData(newstroke_font[ord('?')-ord(' ')]))+',';
  end
  //else if(char='0') then
  //begin
  //json_char:='"0":{"l":[[[0.42857142857142855,-1.0476190476190474],[0.5238095238095237,-1.0476190476190474],[0.6190476190476191,-1],[0.6666666666666666,-0.9523809523809523],[0.7142857142857142,-0.8571428571428571],[0.7619047619047619,-0.6666666666666666],[0.7619047619047619,-0.42857142857142855],[0.7142857142857142,-0.23809523809523808],[0.6666666666666666,-0.14285714285714285],[0.6190476190476191,-0.09523809523809523],[0.5238095238095237,-0.047619047619047616],[0.42857142857142855,-0.047619047619047616],[0.3333333333333333,-0.09523809523809523],[0.2857142857142857,-0.14285714285714285],[0.23809523809523808,-0.23809523809523808],[0.19047619047619047,-0.42857142857142855],[0.19047619047619047,-0.6666666666666666],[0.23809523809523808,-0.8571428571428571],[0.2857142857142857,-0.9523809523809523],[0.3333333333333333,-1],[0.42857142857142855,-1.0476190476190474]]],"w":0.9523809523809523},';
  //end
  else
  begin
       //json_char:='"'+'0'+'":'+removeLastComma(parseNewStrokeData(newstroke_font[ord('0')-ord(' ')]))+',';
       json_char:='"'+char+'":'+removeLastComma(parseNewStrokeData(newstroke_font[ord(char)-ord(' ')]))+',';
  end;
  Result:=json_char;
end;

procedure init_newstroke();
begin
end;

function getFontDataJSON():TString;
var
  json_font_data   : TString;
  i: Integer;
begin
   json_font_data:='"font_data":{';
   for i:=0 to usedChars.Count -1 do
   begin
        json_font_data:= json_font_data + parse_font_char(usedChars.Get(i));
   end;
   if(AnsiLastChar(json_font_data)=',')then
    begin
      json_font_data:=leftStr(json_font_data,Length(json_font_data)-1);
    end;
    json_font_data:= json_font_data + '}';
   Result:=json_font_data;
end;

procedure init_newstroke();
begin
     if (newstroke_font <> Nil) then
     begin
         newstroke_font:=[      //initializing this array with more values crashes Altium
     { // BASIC LATIN (0020-007F) }
     'JZ', { U+20 SPACE  }
     'MWRYSZR[QZRYR[ RRSQGRFSGRSRF',
     'JZNFNJ RVFVJ',
     'H]LM[M RRDL_ RYVJV RS_YD',
     'H\LZO[T[VZWYXWXUWSVRTQPPNOMNLLLJMHNGPFUFXG RRCR^',
     'F^J[ZF RMFOGPIOKMLKKJIKGMF RYZZXYVWUUVTXUZW[YZ',
     'E_[[Z[XZUWPQNNMKMINGPFQFSGTITJSLRMLQKRJTJWKYLZN[Q[SZTYWUXRXP',
     'MWSFQJ',
     'KYVcUbS_R]QZPUPQQLRISGUDVC',
     'KYNcObQ_R]SZTUTQSLRIQGODNC',
     'JZRFRK RMIRKWI ROORKUO',
     'E_JSZS RR[RK',
     'MWSZS[R]Q^',
     'E_JSZS',
     'MWRYSZR[QZRYR[',
     'G][EI`',
     'H\QFSFUGVHWJXNXSWWVYUZS[Q[OZNYMWLSLNMJNHOGQF', { U+30 DIGIT_0  }
     'H\X[L[ RR[RFPINKLL',
     'H\LHMGOFTFVGWHXJXLWOK[X[',
     'H\KFXFQNTNVOWPXRXWWYVZT[N[LZKY',
     'H\VMV[ RQELTYT',
     'H\WFMFLPMOONTNVOWPXRXWWYVZT[O[MZLY',
     'H\VFRFPGOHMKLOLWMYNZP[T[VZWYXWXRWPVOTNPNNOMPLR',
     'H\KFYFP[',
     'H\PONNMMLKLJMHNGPFTFVGWHXJXKWMVNTOPONPMQLSLWMYNZP[T[VZWYXWXSWQVPTO',
     'H\N[R[TZUYWVXRXJWHVGTFPFNGMHLJLOMQNRPSTSVRWQXO',
     'MWRYSZR[QZRYR[ RRNSORPQORNRP',
     'MWSZS[R]Q^ RRNSORPQORNRP',
     'E_ZMJSZY',
     'E_JPZP RZVJV',
     'E_JMZSJY',
     'I[QYRZQ[PZQYQ[ RMGOFTFVGWIWKVMUNSORPQRQS',
     'D_VQUPSOQOOPNQMSMUNWOXQYSYUXVW RVOVWWXXXZW[U[PYMVKRJNKKMIPHTIXK[N]R^V]Y[', { U+40 AT  }
     'I[MUWU RK[RFY[',
     'G\SPVQWRXTXWWYVZT[L[LFSFUGVHWJWLVNUOSPLP',
     'F[WYVZS[Q[NZLXKVJRJOKKLINGQFSFVGWH',
     'G\L[LFQFTGVIWKXOXRWVVXTZQ[L[',
     'H[MPTP RW[M[MFWF',
     'HZTPMP RM[MFWF',
     'F[VGTFQFNGLIKKJOJRKVLXNZQ[S[VZWYWRSR',
     'G]L[LF RLPXP RX[XF',
     'MWR[RF',
     'JZUFUUTXRZO[M[',
     'G\L[LF RX[OO RXFLR',
     'HYW[M[MF',
     'F^K[KFRUYFY[',
     'G]L[LFX[XF',
     'G]PFTFVGXIYMYTXXVZT[P[NZLXKTKMLINGPF',
     'G\L[LFTFVGWHXJXMWOVPTQLQ', { U+50 P_CAP  }
     'G]Z]X\VZSWQVOV RP[NZLXKTKMLINGPFTFVGXIYMYTXXVZT[P[',
     'G\X[QQ RL[LFTFVGWHXJXMWOVPTQLQ',
     'H\LZO[T[VZWYXWXUWSVRTQPPNOMNLLLJMHNGPFUFXG',
     'JZLFXF RR[RF',
     'G]LFLWMYNZP[T[VZWYXWXF',
     'I[KFR[YF',
     'F^IFN[RLV[[F',
     'H\KFY[ RYFK[',
     'I[RQR[ RKFRQYF',
     'H\KFYFK[Y[',
     'KYVbQbQDVD',
     'KYID[_',
     'KYNbSbSDND',
     'LXNHREVH',
     'JZJ]Z]',
     'NVPESH', { U+60 GRAVE  }
     'I\W[WPVNTMPMNN RWZU[P[NZMXMVNTPSUSWR',
     'H[M[MF RMNOMSMUNVOWQWWVYUZS[O[MZ',
     'HZVZT[P[NZMYLWLQMONNPMTMVN',
     'I\W[WF RWZU[Q[OZNYMWMQNOONQMUMWN',
     'I[VZT[P[NZMXMPNNPMTMVNWPWRMT',
     'MYOMWM RR[RISGUFWF',
     'I\WMW^V`UaSbPbNa RWZU[Q[OZNYMWMQNOONQMUMWN',
     'H[M[MF RV[VPUNSMPMNNMO',
     'MWR[RM RRFQGRHSGRFRH',
     'MWRMR_QaObNb RRFQGRHSGRFRH',
     'IZN[NF RPSV[ RVMNU',
     'MXU[SZRXRF',
     'D`I[IM RIOJNLMOMQNRPR[ RRPSNUMXMZN[P[[',
     'I\NMN[ RNOONQMTMVNWPW[',
     'H[P[NZMYLWLQMONNPMSMUNVOWQWWVYUZS[P[',
     'H[MMMb RMNOMSMUNVOWQWWVYUZS[O[MZ', { U+70 P_SMALL  }
     'I\WMWb RWZU[Q[OZNYMWMQNOONQMUMWN',
     'KXP[PM RPQQORNTMVM',
     'J[NZP[T[VZWXWWVUTTQTOSNQNPONQMTMVN',
     'MYOMWM RRFRXSZU[W[',
     'H[VMV[ RMMMXNZP[S[UZVY',
     'JZMMR[WM',
     'G]JMN[RQV[ZM',
     'IZL[WM RLMW[',
     'JZMMR[ RWMR[P`OaMb',
     'IZLMWML[W[',
     'KYVcUcSbR`RVQTOSQRRPRFSDUCVC',
     'H\RbRD',
     'KYNcOcQbR`RVSTUSSRRPRFQDOCNC',
     'KZMHNGPFTHVGWF',
     'F^K[KFYFY[K['];
     end;

end;
