function getZonesJSON(Board: IPCB_Board): TString;

var
    currentProject : IProject;
    BoardObjectIteratorHandle : IPCB_BoardIterator;
    Polygon                   : IPCB_Primitive;

    json_zones: TString;
    json_zones_tmp  : TString;
    json_zones_F:TString;
    json_zones_B:TString;

    i: Integer;

begin

json_zones := '"zones":{"F":[],"B":[]}';
    json_zones_F := '';
    json_zones_B :='';

try

       BoardObjectIteratorHandle := Board.BoardIterator_Create;
       BoardObjectIteratorHandle.AddFilter_ObjectSet(MkSet(ePolyObject));
       BoardObjectIteratorHandle.AddFilter_IPCB_LayerSet(Layerset.Union(LayerSet.eTopLayer,Layerset.eBottomLayer));
       BoardObjectIteratorHandle.AddFilter_Method(eProcessAll);

       Polygon := BoardObjectIteratorHandle.FirstPCBObject;
        while (Polygon <> Nil) Do
        begin
            //ShowMessage(Track.Detail+' Layer '+IntToStr(Track.Layer)+' Pos '+FloatToStr(CoordToMMs(Track.X1)));


            json_zones_tmp := '{"polygons":[[';
             
              for i:=0 to Polygon.PointCount -1 do
              begin
                json_zones_tmp := json_zones_tmp + '['+FloatToStr(CoordToMMs(Polygon.Segments[i].vX))+','+FloatToStr(-CoordToMMs(Polygon.Segments[i].vY))+'],';
              end;


              if(AnsiLastChar(json_zones_tmp)=',')then
                begin
                  json_zones_tmp:=leftStr(json_zones_tmp,Length(json_zones_tmp)-1);
                end;


             json_zones_tmp := json_zones_tmp + ']]';
            if(Polygon.net <> Nil)then
            begin
                 json_zones_tmp := json_zones_tmp + ',"net":"'+Polygon.Net.Name+'"'
            end;
            json_zones_tmp := json_zones_tmp +'},';


            if(Polygon.Layer = eTopLayer  ) then   //Top
            begin
                json_zones_F := json_zones_F + json_zones_tmp;
            end
            else if (Polygon.Layer = eBottomLayer) then   //Bottom
            begin
                json_zones_B := json_zones_B + json_zones_tmp;
            end;

            Polygon := BoardObjectIteratorHandle.NextPCBObject;

        end;

    finally
    end;

    if(AnsiLastChar(json_zones_F)=',')then
    begin
      json_zones_F:=leftStr(json_zones_F,Length(json_zones_F)-1);
    end;

    if(AnsiLastChar(json_zones_B)=',')then
    begin
      json_zones_B:=leftStr(json_zones_B,Length(json_zones_B)-1);
    end;

    json_zones:= '"zones":{"F":['+json_zones_F+'],"B":['+json_zones_B+']}'  ;

    Result := json_zones;
end;
