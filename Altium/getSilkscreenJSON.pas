function getSilkscreenJSON(Board: IPCB_Board): TString;

var
    currentProject : IProject;
    BoardObjectIteratorHandle : IPCB_BoardIterator;
    Track                   : IPCB_Primitive;
    Text : IPCB_Primitive;

    json_silkscreen: TString;
    json_silkscreen_F : TString;
    json_silkscreen_B  : TString;
    json_silkscreen_tmp: TString;

begin

    json_silkscreen_F :='';
    json_silkscreen_B  :='';

    try

       BoardObjectIteratorHandle := Board.BoardIterator_Create;
       BoardObjectIteratorHandle.AddFilter_ObjectSet(MkSet(eTrackObject));
       BoardObjectIteratorHandle.AddFilter_IPCB_LayerSet(Layerset.Union(LayerSet.eTopOverlay,LayerSet.eBottomOverlay));
       BoardObjectIteratorHandle.AddFilter_Method(eProcessAll);

       Track := BoardObjectIteratorHandle.FirstPCBObject;
        while (Track <> Nil) Do
        begin
            //ShowMessage(Track.Detail+' Layer '+IntToStr(Track.Layer)+' Pos '+FloatToStr(CoordToMMs(Track.X1)));

            json_silkscreen_tmp := '{"type":"segment","start":['
            +FloatToStr(CoordToMMs(Track.X1))+','
            +FloatToStr(CoordToMMs(-Track.Y1))+'],"end":['
            +FloatToStr(CoordToMMs(Track.X2))+','
            +FloatToStr(CoordToMMs(-Track.Y2))+'],"width":"'+FloatToStr(CoordToMMs(Track.Width))+'"'
            +'},';


            if(Track.Layer = LayerSet.eTopOverlay  ) then   //Top
            begin
                json_silkscreen_F := json_silkscreen_F + json_silkscreen_tmp;
            end
            else if (Track.Layer = LayerSet.eBottomOverlay) then   //Bottom
            begin
                json_silkscreen_B := json_silkscreen_B + json_silkscreen_tmp;
            end;

            Track := BoardObjectIteratorHandle.NextPCBObject;

        end;

    finally
    end;


    try

       BoardObjectIteratorHandle := Board.BoardIterator_Create;
       BoardObjectIteratorHandle.AddFilter_ObjectSet(MkSet(eTextObject));
       BoardObjectIteratorHandle.AddFilter_IPCB_LayerSet(Layerset.Union(LayerSet.eTopOverlay,LayerSet.eBottomOverlay));
       BoardObjectIteratorHandle.AddFilter_Method(eProcessAll);

       Text := BoardObjectIteratorHandle.FirstPCBObject;
        while (Text <> Nil) Do
        begin

            //ShowMessage(Text.Descriptor+' Layer '+IntToStr(Text.Layer));//+' Pos '+FloatToStr(CoordToMMs(Text.)));

            json_silkscreen_tmp:='';
            //if(Text.Layer = 33) then
            if(Not Text.IsHidden)then
            begin
                        json_silkscreen_tmp := '{"pos":['
                        +FloatToStr(CoordToMMs(Text.XLocation ))+','
                        +FloatToStr(-CoordToMMs(Text.YLocation ))+'],'
                        +'"text":"'+Escape(visText(Text.Text))+'",'
                        +'"height":'+'1'+','
                        +'"width":'+'3'+','
                        +'"horiz_justify":'+'"0"'+','
                        +'"thickness":'+'0.2'+','
                        +'"attr":'+'[]'+','
                        +'"angle":'+FloatToStr(Text.Rotation)+''
                        +'},';
            end;


            if(Text.Layer = LayerSet.eTopOverlay  ) then   //Top
            begin
                json_silkscreen_F := json_silkscreen_F + json_silkscreen_tmp;
            end
            else if (Text.Layer = LayerSet.eBottomOverlay) then   //Bottom
            begin
                json_silkscreen_B := json_silkscreen_B + json_silkscreen_tmp;
            end;

            Text := BoardObjectIteratorHandle.NextPCBObject;

        end;

    finally
    end;




    if(AnsiLastChar(json_silkscreen_F)=',')then
    begin
      json_silkscreen_F:=leftStr(json_silkscreen_F,Length(json_silkscreen_F)-1);
    end;

    if(AnsiLastChar(json_silkscreen_B)=',')then
    begin
      json_silkscreen_B:=leftStr(json_silkscreen_B,Length(json_silkscreen_B)-1);
    end;



     json_silkscreen := '"silkscreen":{"F":['+json_silkscreen_F+'],"B":['+json_silkscreen_B+']}';


    Result := json_silkscreen;
end;
