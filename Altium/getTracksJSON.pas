function getTracksJSON(Board: IPCB_Board): TString;

var
    currentProject : IProject;
    BoardObjectIteratorHandle : IPCB_BoardIterator;
    Track                   : IPCB_Primitive;
    Via                   : IPCB_Primitive;

    json_tracks: TString;
    json_tracks_F : TString;
    json_tracks_B: TString;
    json_tracks_tmp: TString;

begin

json_tracks_tmp := '';
json_tracks_F : ='';
json_tracks_B := '';

    try

       BoardObjectIteratorHandle := Board.BoardIterator_Create;
       BoardObjectIteratorHandle.AddFilter_ObjectSet(MkSet(eTrackObject));
       BoardObjectIteratorHandle.AddFilter_IPCB_LayerSet(LayerSet.SignalLayers);
       BoardObjectIteratorHandle.AddFilter_Method(eProcessAll);

       Track := BoardObjectIteratorHandle.FirstPCBObject;
        while (Track <> Nil) Do
        begin
            //ShowMessage(Track.Detail+' Layer '+IntToStr(Track.Layer)+' Pos '+FloatToStr(CoordToMMs(Track.X1)));


            json_tracks_tmp := '{"start":['
            +FloatToStr(CoordToMMs(Track.X1))+','
            +FloatToStr(-CoordToMMs(Track.Y1))+'],'
            +'"end":['
            +FloatToStr(CoordToMMs(Track.X2))+','
            +FloatToStr(-CoordToMMs(Track.Y2))+'],'
            +'"width":"'+FloatToStr(CoordToMMs(Track.Width))+'"';
            if(Track.net <> Nil)then
            begin
                 json_tracks_tmp := json_tracks_tmp + ',"net":"'+Track.Net.Name+'"'
            end;
            json_tracks_tmp := json_tracks_tmp +'},';


            if(Track.Layer = 1  ) then   //Top
            begin
                json_tracks_F := json_tracks_F + json_tracks_tmp;
            end
            else if (Track.Layer = 32) then   //Bottom
            begin
                json_tracks_B := json_tracks_B + json_tracks_tmp;
            end;

            Track := BoardObjectIteratorHandle.NextPCBObject;

        end;

    finally
    end;

    //handle vias

    try

       BoardObjectIteratorHandle := Board.BoardIterator_Create;
       BoardObjectIteratorHandle.AddFilter_ObjectSet(MkSet(eViaObject));
       BoardObjectIteratorHandle.AddFilter_IPCB_LayerSet(LayerSet.AllLayers);
       BoardObjectIteratorHandle.AddFilter_Method(eProcessAll);

       Via := BoardObjectIteratorHandle.FirstPCBObject;
        while (Via <> Nil) Do
        begin
            //ShowMessage(Via.Detail+' Layer '+IntToStr(Via.Layer)+' Pos '+FloatToStr(CoordToMMs(Via.X)));

            json_tracks_tmp := '{"start":['
            +FloatToStr(CoordToMMs(Via.X))+','
            +FloatToStr(CoordToMMs(-Via.Y))+'],'
            +'"end":['
            +FloatToStr(CoordToMMs(Via.X))+','
            +FloatToStr(CoordToMMs(-Via.Y))+'],'
            +'"width":"'+FloatToStr(CoordToMMs(Via.Size))+'"';   //Via.HoleSize
            if(Via.net <> Nil)then
            begin
                 json_tracks_tmp := json_tracks_tmp + ',"net":"'+Via.Net.Name+'"'
            end;
            json_tracks_tmp := json_tracks_tmp +'},';


            if(Via.Layer = 74  ) then   //Via
            begin
                json_tracks_F := json_tracks_F + json_tracks_tmp;
                json_tracks_B := json_tracks_B + json_tracks_tmp;
            end;

            Via := BoardObjectIteratorHandle.NextPCBObject;

        end;

    finally
    end;


    if(AnsiLastChar(json_tracks_F)=',')then
    begin
      json_tracks_F:=leftStr(json_tracks_F,Length(json_tracks_F)-1);
    end;

    if(AnsiLastChar(json_tracks_B)=',')then
    begin
      json_tracks_B:=leftStr(json_tracks_B,Length(json_tracks_B)-1);
    end;

    json_tracks:= '"tracks":{"F":['+json_tracks_F+'],"B":['+json_tracks_B+']}'  ;

    Result := json_tracks;
end;
